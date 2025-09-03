# AWS EKS Reference Architecture - Layered Terraform Approach

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.16883393.svg)](https://doi.org/10.5281/zenodo.16883393)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This repository provides a **production-ready, layered Amazon EKS** architecture built with **Terraform 1.5+** using a **4-layer deployment approach**. It creates a highly-available Kubernetes cluster with **prefix delegation** enabled to overcome IP limitations, deployed across multiple layers for better reliability and maintainability.

> **Goal:** Provide a robust, scalable EKS deployment that eliminates common Terraform state management issues through proper layering and includes comprehensive IP optimization strategies.

---

## 🏗️ Layered Architecture Approach

This deployment uses a **4-layer approach** that eliminates common Terraform issues like state locks, timeouts, and dependency conflicts:

```
┌─────────────────────────────────────────┐
│  Layer 4: Applications                  │  ← Helm charts, K8s manifests
├─────────────────────────────────────────┤
│  Layer 3: EKS Data Plane               │  ← Node groups, addons
├─────────────────────────────────────────┤  
│  Layer 2: EKS Control Plane            │  ← EKS cluster, IRSA
├─────────────────────────────────────────┤
│  Layer 1: Base Infrastructure          │  ← VPC, subnets, security
└─────────────────────────────────────────┘
```

### Layer Benefits

- ✅ **No State Lock Conflicts**: Each layer has separate state files
- ✅ **Proper Resource Dependencies**: Layers depend on previous layer outputs
- ✅ **Appropriate Timeouts**: EKS cluster gets 30+ minutes, not 10 minutes
- ✅ **Selective Deployment**: Deploy/update only what you need
- ✅ **Easier Troubleshooting**: Isolate issues to specific layers
- ✅ **Better Team Collaboration**: Different teams can own different layers

---

## 🚀 Quick Start

### Prerequisites

- AWS CLI v2+ configured
- Terraform 1.5+
- kubectl

### One-Command Deployment

```bash
./deploy.sh dev deploy
```

### Manual Layer-by-Layer Deployment

```bash
# Layer 1: Base Infrastructure (VPC, subnets, security groups)
cd env/dev/1-base-infrastructure
terraform init
terraform apply -var-file=dev.tfvars

# Layer 2: EKS Control Plane (cluster, IRSA)
cd ../2-eks-control-plane  
terraform init
terraform apply -var-file=dev.tfvars

# Layer 3: EKS Data Plane (node groups, addons)
cd ../3-eks-data-plane
terraform init
terraform apply -var-file=dev.tfvars

# Configure kubectl to connect to your EKS cluster
aws eks update-kubeconfig --region us-east-2 --name eks-dev-custom

# Verify cluster connectivity
kubectl get nodes
kubectl get pods -A

# Layer 4: Applications (optional)
cd ../4-applications
terraform init
terraform apply -var-file=dev.tfvars
```

### Cleanup

```bash
./deploy.sh dev destroy
```

---

## 📐 Architecture Components

### Layer 1: Base Infrastructure
- **VPC** with configurable CIDR (`10.0.0.0/16` default)
- **Multi-AZ Setup** (2 AZs default)
- **Public & Private Subnets**
- **NAT Gateways** with proper EIP lifecycle management
- **Security Groups** for EKS and node groups
- **IAM Roles** for cluster and nodes
- **CloudWatch Log Groups** for monitoring

### Layer 2: EKS Control Plane  
- **EKS Cluster** with Kubernetes 1.33
- **30-minute timeouts** (no more stuck deployments!)
- **IRSA** (IAM Roles for Service Accounts)
- **Proper lifecycle management**
- **KMS encryption** (optional)

### Layer 3: EKS Data Plane
- **Managed Node Groups** with spot instances
- **VPC CNI** with prefix delegation enabled
- **Core addons**: CoreDNS, kube-proxy, EBS CSI driver
- **15-minute timeouts** for all addon operations
- **Proper dependency management**

### Layer 4: Applications
- **Placeholder** for application deployments
- **Helm charts**, Kubernetes manifests
- **Application-specific resources**

---

## 🔧 Configuration

Each layer has its own `dev.tfvars` file for configuration:

### Layer 1: Base Infrastructure
```hcl
customer_name = "your-company"
vpc_cidr     = "10.0.0.0/16"
az_count     = 2
enable_kms_encryption = false
```

### Layer 2: EKS Control Plane
```hcl
kubernetes_version  = "1.33"
public_access_cidrs = ["0.0.0.0/0"]
```

### Layer 3: EKS Data Plane
```hcl
node_group_instance_types = ["t3.small"]
node_group_capacity_type  = "SPOT"
node_group_desired_size   = 2
```

---

## 🧪 IP Optimization Strategy

This architecture addresses EKS IP limitations through:

### Prefix Delegation (Enabled by Default)
- **ENABLE_PREFIX_DELEGATION=true** in VPC CNI
- **WARM_PREFIX_TARGET=1** for optimal resource usage
- **Increases pod density** from ~30 to ~250+ pods per node
- **No custom networking required** (simplified approach)

### Benefits
- ✅ **Higher pod density** without complex networking
- ✅ **Simplified configuration** compared to custom networking
- ✅ **Better resource utilization** 
- ✅ **Cost optimization** through spot instances

### Verification
```bash
# Check pod capacity
kubectl describe node | grep -E "(Allocatable|max-pods)"

# Verify VPC CNI configuration  
kubectl get pods -n kube-system -l k8s-app=aws-node -o yaml | grep -A5 env:
```

---

## 🔍 Troubleshooting

### Common Issues and Solutions

1. **Terraform State Locks**
   - ✅ **Solved**: Each layer has separate state files
   - No more `terraform force-unlock` needed

2. **EKS Creation Timeouts**  
   - ✅ **Solved**: 30-minute timeouts in Layer 2
   - Proper dependency management prevents interruptions

3. **Addon Deployment Failures**
   - ✅ **Solved**: Addons deployed after node groups in Layer 3
   - 15-minute timeouts prevent stuck operations

4. **Resource Dependencies**
   - ✅ **Solved**: Layers use remote state data sources
   - Proper dependency chain ensures correct order

5. **kubectl Connection Issues**
   - **Problem**: `Unable to connect to server: dial tcp: lookup [cluster-endpoint]`
   - **Solution**: Configure kubectl after Layer 3 deployment
   ```bash
   aws eks update-kubeconfig --region us-east-2 --name eks-dev-custom
   kubectl get nodes  # Should show 2 nodes in Ready state
   ```

### Layer-Specific Debugging

```bash
# Check layer outputs
terraform output -json

# Verify remote state access
terraform console
> data.terraform_remote_state.base_infrastructure.outputs

# Check resource status
terraform show | grep -A5 "resource_name"
```

---

## 📋 Directory Structure

```
eks-without-ip-limit/
├── deploy.sh                     # Main deployment orchestration script
├── modules/                      # Reusable Terraform modules
│   ├── network/                 # VPC, subnets, NAT gateways
│   ├── security/                # Security groups, IAM roles
│   ├── eks/                     # EKS cluster module
│   ├── monitoring/              # CloudWatch, logging
│   └── addons/                  # EKS addons module
└── env/
    └── dev/                     # Development environment
        ├── 1-base-infrastructure/    # Layer 1: VPC, security, monitoring
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   ├── backend.tf
        │   └── dev.tfvars
        ├── 2-eks-control-plane/      # Layer 2: EKS cluster, IRSA
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   ├── backend.tf
        │   └── dev.tfvars
        ├── 3-eks-data-plane/         # Layer 3: Node groups, addons
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   ├── validation.tf
        │   ├── backend.tf
        │   └── dev.tfvars
        └── 4-applications/           # Layer 4: Applications (placeholder)
            └── main.tf
```

---

## 🤝 Contributing

1. **Fork** the repository
2. **Create a feature branch** for your layer changes
3. **Test** your changes with `./deploy.sh dev deploy`
4. **Submit a Pull Request** with layer-specific details

---

## 📚 References

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [VPC CNI Prefix Delegation](https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

**Note**: This layered approach solves the fundamental Terraform state management issues that plague large infrastructure deployments. Each layer is independently deployable and maintainable, making this architecture suitable for production environments.