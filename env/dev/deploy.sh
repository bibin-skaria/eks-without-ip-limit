#!/bin/bash

set -e

echo "🚀 Starting layered EKS deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to deploy a layer
deploy_layer() {
    local layer_path=$1
    local layer_name=$2
    
    print_status "Deploying Layer: $layer_name"
    echo "📁 Working directory: $layer_path"
    
    cd "$layer_path"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan
    print_status "Creating Terraform plan..."
    terraform plan -var-file=dev.tfvars
    
    # Apply with timeout and parallelism control
    print_status "Applying Terraform configuration..."
    terraform apply -var-file=dev.tfvars -auto-approve -parallelism=2
    
    print_success "✅ Layer $layer_name deployed successfully!"
    echo ""
    
    cd - > /dev/null
}

# Function to verify deployment
verify_layer() {
    local layer_path=$1
    local layer_name=$2
    
    print_status "Verifying Layer: $layer_name"
    cd "$layer_path"
    
    terraform show -json > /dev/null
    if [ $? -eq 0 ]; then
        print_success "✅ Layer $layer_name verification passed!"
    else
        print_error "❌ Layer $layer_name verification failed!"
        exit 1
    fi
    
    cd - > /dev/null
}

# Main deployment sequence
main() {
    local base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    print_status "Starting deployment from: $base_dir"
    
    # Layer 1: Base Infrastructure
    deploy_layer "$base_dir/1-base-infrastructure" "1 - Base Infrastructure"
    verify_layer "$base_dir/1-base-infrastructure" "1 - Base Infrastructure"
    
    # Layer 2: EKS Control Plane  
    deploy_layer "$base_dir/2-eks-control-plane" "2 - EKS Control Plane"
    verify_layer "$base_dir/2-eks-control-plane" "2 - EKS Control Plane"
    
    # Layer 3: EKS Data Plane
    deploy_layer "$base_dir/3-eks-data-plane" "3 - EKS Data Plane"
    verify_layer "$base_dir/3-eks-data-plane" "3 - EKS Data Plane"
    
    # Layer 4: Applications (optional)
    if [ -f "$base_dir/4-applications/main.tf" ] && [ -s "$base_dir/4-applications/main.tf" ]; then
        deploy_layer "$base_dir/4-applications" "4 - Applications"
        verify_layer "$base_dir/4-applications" "4 - Applications"
    else
        print_warning "Layer 4 (Applications) is empty, skipping..."
    fi
    
    print_success "🎉 All layers deployed successfully!"
    
    # Get kubectl configuration
    print_status "Configuring kubectl..."
    aws eks update-kubeconfig --region us-east-2 --name eks-dev-custom
    
    print_success "🏁 Deployment complete! Your EKS cluster is ready."
    echo ""
    echo "Next steps:"
    echo "  1. Verify cluster: kubectl get nodes"
    echo "  2. Check addons: kubectl get pods -n kube-system" 
    echo "  3. Test prefix delegation: kubectl describe node | grep 'max-pods'"
}

# Cleanup function
cleanup() {
    local base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    print_warning "🧹 Starting cleanup (destroying all layers)..."
    
    # Destroy in reverse order
    for layer in "4-applications" "3-eks-data-plane" "2-eks-control-plane" "1-base-infrastructure"; do
        if [ -d "$base_dir/$layer" ] && [ -f "$base_dir/$layer/main.tf" ]; then
            print_status "Destroying Layer: $layer"
            cd "$base_dir/$layer"
            terraform destroy -var-file=dev.tfvars -auto-approve || print_error "Failed to destroy $layer"
            cd - > /dev/null
        fi
    done
    
    print_success "🧹 Cleanup complete!"
}

# Handle script arguments
case "${1:-}" in
    "cleanup"|"destroy")
        cleanup
        ;;
    "deploy"|""|"apply") 
        main
        ;;
    *)
        echo "Usage: $0 [deploy|cleanup]"
        echo "  deploy:  Deploy all layers (default)"
        echo "  cleanup: Destroy all layers"
        exit 1
        ;;
esac