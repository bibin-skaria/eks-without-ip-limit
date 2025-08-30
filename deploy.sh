#!/bin/bash

# EKS Infrastructure Deployment Script
# This script deploys the complete EKS infrastructure in the correct order
# Usage: ./deploy.sh [environment] [action]
# Examples: 
#   ./deploy.sh dev deploy
#   ./deploy.sh dev destroy

set -e  # Exit on any error

# Configuration
ENVIRONMENT=${1:-dev}
ACTION=${2:-deploy}
REGION="us-east-2"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    echo "EKS Infrastructure Deployment Script"
    echo ""
    echo "Usage: $0 [environment] [action]"
    echo ""
    echo "Arguments:"
    echo "  environment    Environment to deploy (default: dev)"
    echo "  action         Action to perform: deploy, destroy, plan (default: deploy)"
    echo ""
    echo "Examples:"
    echo "  $0 dev deploy     Deploy dev environment"
    echo "  $0 dev destroy    Destroy dev environment"  
    echo "  $0 dev plan       Plan dev environment changes"
    echo ""
}

# Validate environment
validate_environment() {
    if [[ ! -d "$PROJECT_ROOT/env/$ENVIRONMENT" ]]; then
        log_error "Environment '$ENVIRONMENT' does not exist!"
        log_error "Available environments: $(ls $PROJECT_ROOT/env/)"
        exit 1
    fi
}

# Check AWS credentials
check_aws_credentials() {
    log_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        log_error "AWS credentials not configured or invalid!"
        log_error "Please run: aws configure"
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local region=$(aws configure get region || echo "us-east-2")
    log_success "AWS credentials valid - Account: $account_id, Region: $region"
}

# Initialize Terraform for a layer
terraform_init() {
    local layer_path=$1
    local layer_name=$2
    
    log_info "Initializing Terraform for $layer_name..."
    cd "$layer_path"
    
    if ! terraform init -input=false; then
        log_error "Terraform init failed for $layer_name"
        exit 1
    fi
    
    log_success "Terraform initialized for $layer_name"
}

# Plan Terraform changes
terraform_plan() {
    local layer_path=$1
    local layer_name=$2
    
    log_info "Planning changes for $layer_name..."
    cd "$layer_path"
    
    if terraform plan -var-file=$ENVIRONMENT.tfvars -detailed-exitcode; then
        log_success "No changes needed for $layer_name"
        return 0
    elif [ $? -eq 2 ]; then
        log_warning "Changes detected for $layer_name"
        return 2
    else
        log_error "Terraform plan failed for $layer_name"
        exit 1
    fi
}

# Apply Terraform configuration
terraform_apply() {
    local layer_path=$1
    local layer_name=$2
    local timeout=$3
    
    log_info "Deploying $layer_name..."
    cd "$layer_path"
    
    # Set timeout based on layer (NAT gateways and EKS take longer)
    local tf_timeout=""
    if [[ -n "$timeout" ]]; then
        tf_timeout="-timeout=$timeout"
    fi
    
    if terraform apply -var-file=$ENVIRONMENT.tfvars -auto-approve; then
        log_success "$layer_name deployed successfully"
    else
        log_error "Failed to deploy $layer_name"
        exit 1
    fi
}

# Destroy Terraform configuration
terraform_destroy() {
    local layer_path=$1
    local layer_name=$2
    local timeout=$3
    
    log_info "Destroying $layer_name..."
    cd "$layer_path"
    
    if terraform destroy -var-file=$ENVIRONMENT.tfvars -auto-approve; then
        log_success "$layer_name destroyed successfully"
    else
        log_error "Failed to destroy $layer_name"
        exit 1
    fi
}

# Deploy infrastructure
deploy_infrastructure() {
    local env_path="$PROJECT_ROOT/env/$ENVIRONMENT"
    
    log_info "Starting deployment of $ENVIRONMENT environment..."
    
    # Layer 1: Base Infrastructure
    if [[ -d "$env_path/1-base-infrastructure" ]]; then
        terraform_init "$env_path/1-base-infrastructure" "Base Infrastructure"
        terraform_apply "$env_path/1-base-infrastructure" "Base Infrastructure" "900"
    fi
    
    # Layer 2: EKS Control Plane  
    if [[ -d "$env_path/2-eks-control-plane" ]]; then
        terraform_init "$env_path/2-eks-control-plane" "EKS Control Plane"
        terraform_apply "$env_path/2-eks-control-plane" "EKS Control Plane" "1800"
    fi
    
    # Layer 3: EKS Data Plane
    if [[ -d "$env_path/3-eks-data-plane" ]]; then
        terraform_init "$env_path/3-eks-data-plane" "EKS Data Plane"
        terraform_apply "$env_path/3-eks-data-plane" "EKS Data Plane" "1200"
    fi
    
    # Layer 4: Applications (if exists)
    if [[ -d "$env_path/4-applications" ]]; then
        terraform_init "$env_path/4-applications" "Applications"
        terraform_apply "$env_path/4-applications" "Applications" "600"
    fi
    
    log_success "🎉 Deployment completed successfully!"
    
    # Show cluster connection info
    show_cluster_info
}

# Destroy infrastructure (reverse order)
destroy_infrastructure() {
    local env_path="$PROJECT_ROOT/env/$ENVIRONMENT"
    
    log_warning "Starting destruction of $ENVIRONMENT environment..."
    log_warning "This will DELETE all resources. Press Ctrl+C to cancel in the next 10 seconds..."
    sleep 10
    
    # Layer 4: Applications (if exists)
    if [[ -d "$env_path/4-applications" ]]; then
        terraform_destroy "$env_path/4-applications" "Applications" "600"
    fi
    
    # Layer 3: EKS Data Plane
    if [[ -d "$env_path/3-eks-data-plane" ]]; then
        terraform_destroy "$env_path/3-eks-data-plane" "EKS Data Plane" "1200"
    fi
    
    # Layer 2: EKS Control Plane
    if [[ -d "$env_path/2-eks-control-plane" ]]; then
        terraform_destroy "$env_path/2-eks-control-plane" "EKS Control Plane" "900"
    fi
    
    # Layer 1: Base Infrastructure
    if [[ -d "$env_path/1-base-infrastructure" ]]; then
        terraform_destroy "$env_path/1-base-infrastructure" "Base Infrastructure" "900"
    fi
    
    log_success "🗑️  Infrastructure destroyed successfully!"
}

# Plan infrastructure changes
plan_infrastructure() {
    local env_path="$PROJECT_ROOT/env/$ENVIRONMENT"
    
    log_info "Planning changes for $ENVIRONMENT environment..."
    
    # Plan all layers
    for layer in 1-base-infrastructure 2-eks-control-plane 3-eks-data-plane 4-applications; do
        if [[ -d "$env_path/$layer" ]]; then
            terraform_init "$env_path/$layer" "$layer"
            terraform_plan "$env_path/$layer" "$layer"
        fi
    done
}

# Show cluster connection information
show_cluster_info() {
    local control_plane_path="$PROJECT_ROOT/env/$ENVIRONMENT/2-eks-control-plane"
    
    if [[ -d "$control_plane_path" ]]; then
        log_info "Cluster Information:"
        cd "$control_plane_path"
        
        # Get cluster name from terraform output
        local cluster_name=$(terraform output -raw cluster_id 2>/dev/null || echo "eks-${ENVIRONMENT}-custom")
        local cluster_endpoint=$(terraform output -raw cluster_endpoint 2>/dev/null || echo "")
        local kubectl_config=$(terraform output -raw configure_kubectl 2>/dev/null || echo "")
        
        echo ""
        echo "📋 Cluster Details:"
        echo "   Name: $cluster_name"
        echo "   Endpoint: $cluster_endpoint"
        echo ""
        echo "🔧 To connect to your cluster, run:"
        echo "   $kubectl_config"
        echo ""
        echo "🚀 Verify your cluster:"
        echo "   kubectl get nodes"
        echo "   kubectl get pods -A"
        echo ""
    fi
}

# Main script execution
main() {
    # Handle help
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # Validate inputs
    if [[ ! "$ACTION" =~ ^(deploy|destroy|plan)$ ]]; then
        log_error "Invalid action: $ACTION"
        log_error "Valid actions: deploy, destroy, plan"
        exit 1
    fi
    
    # Header
    echo "=========================================="
    echo "  EKS Infrastructure Deployment Script   "
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Action: $ACTION"
    echo "Region: $REGION"
    echo "=========================================="
    echo ""
    
    # Validate environment and prerequisites
    validate_environment
    check_aws_credentials
    
    # Execute action
    case "$ACTION" in
        deploy)
            deploy_infrastructure
            ;;
        destroy)
            destroy_infrastructure
            ;;
        plan)
            plan_infrastructure
            ;;
    esac
    
    log_success "Script completed successfully!"
}

# Run main function with all arguments
main "$@"