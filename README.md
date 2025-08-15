# AWS EKS Reference Architecture (Terraform 1.5, Module-based)

This repository contains an opinionated, production-ready **Amazon EKS** architecture built with **Terraform 1.5** using a **module-based** layout.  
It creates a highly-available Kubernetes control plane and worker nodes across **two Availability Zones**, with segmented **public** and **private** subnets, **NAT Gateways**, **bastion hosts**, and **Elastic Load Balancing (NLB/ALB)** for north–south traffic.

> **Goal:** Provide a clean, extensible baseline that teams can fork, customize, and contribute to via Pull Requests—covering networking, security, cluster add-ons, and pod-IP scalability (no “IP limit” surprises).

---

## 📐 Architecture Overview

![EKS Architecture](docs/diagrams/aws-eks-architecture.png)

**Layers & components**

- **VPC**
  - /16 (configurable) CIDR with **2× AZs**
  - **Public subnets** (ELB/NLB, NAT GW, bastion)
  - **Private subnets** (EKS worker nodes, app workloads)
  - **Route tables** for public/private paths
  - **Internet Gateway** and **NAT Gateways** (1 per AZ)

- **Access & Security**
  - **Bastion host** in each AZ (public subnet, locked by SG / optional SSM)
  - **Security Groups** for control plane ↔ nodes, load balancers, bastion
  - **IRSA** (IAM Roles for Service Accounts) for add-ons
  - **KMS** (optional) for secret encryption at rest

- **EKS**
  - Managed control plane (version pinned)
  - **Managed Node Groups** across both AZs
  - Core **add-ons**: VPC CNI, CoreDNS, kube-proxy
  - Optional add-ons: Cluster Autoscaler or Karpenter, EBS/EFS CSI, Metrics Server, Ingress Controller

- **Load Balancing**
  - **NLB/ALB** in public subnets for ingress
  - **NodePort**/Target Groups to workloads in private subnets

---

## 🚀 What This Stack Intends To Do

- Stand up a **secure, HA EKS cluster** with sane defaults for production.
- Provide a **module-based Terraform** layout that’s easy to read and extend.
- **Avoid pod-IP exhaustion** with two supported strategies:
  1) **AWS VPC CNI custom networking + prefix delegation** (pods draw addresses from pod-only subnets; much higher pod density per node).  
  2) **Overlay CNI** (e.g., Cilium with cluster-pool IPAM) so pods don’t consume VPC IPs at all.  
   _Defaults target strategy (1)._
- Make contributions easy (fork, branch, PR) for **features**, **bug fixes**, and **quick fixes**.

---

## 📦 Versions (Pinned & Tested)

| Component              | Version / Constraint                              | Notes |
|---|---|---|
| **Terraform**          | **1.5.x** (required)                              | Repo created/tested on 1.5; lockfile recommended to commit. |
| **AWS Provider**       | `~> 5.0`                                          | Pin major to 5; supports latest EKS & VPC resources. |
| **Kubernetes Provider**| `~> 2.0`                                          | For cluster resources after EKS is up. |
| **Helm Provider**      | `~> 2.0`                                          | For add-ons installed via Helm. |
| **EKS (Kubernetes)**   | **1.29** (default)                                | Update per EKS support policy when needed. |
| **Core Add-ons**       | VPC CNI / CoreDNS / kube-proxy pinned via vars    | Exact versions set via variables; update safely with plan/apply. |

> If you bump EKS or add-on versions, please update the table above and the variables in `/env/…/` and submit a PR.

---

## 🧱 Repository Layout (Module-based)

```
.
├── modules/
│   ├── network/          # VPC, subnets, IGW, NAT, route tables
│   ├── security/         # IAM, IRSA, KMS (optional), security groups
│   ├── eks/              # EKS cluster, node groups, auth config
│   ├── addons/           # VPC CNI, CoreDNS, kube-proxy, CSI, autoscaling, ingress
│   └── bastion/          # Bastion hosts + minimal SSM/SSH setup
├── env/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── versions.tf   # Terraform + provider constraints
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf (optional pattern)
│   └── prod/
│       └── ...
├── docs/
│   └── diagrams/
│       └── aws-eks-architecture.png
├── Makefile              # helper targets (fmt, validate, plan, apply, destroy)
├── .pre-commit-config.yaml
├── .gitignore
├── README.md
└── LICENSE
```

---

## 🔧 Key Implementation Notes

### Pod IP Strategy (no “IP limits”)
**Default:** AWS VPC CNI with:
- **Custom networking**: dedicated **pod subnets** (can be secondary CIDR blocks) per AZ via `ENIConfig`.
- **Prefix delegation**: assign IP prefixes to ENIs (dramatically increases pod density).

Variables let you switch to **Cilium (overlay)** mode, which allocates pod IPs from a cluster CIDR (e.g., `10.244.0.0/16`) and SNATs via the node—removing dependency on VPC IP inventory.

### High Availability
- 2× AZ minimum, subnets split per AZ.
- 1× NAT Gateway per AZ (failover friendly).
- Managed Node Groups across AZs.

### Security
- **Private nodes** (no public IPs) behind NAT.
- **IRSA** for least-privileged access to AWS services.
- Bastion login: either **SSM Session Manager** or SSH with restricted Source IPs.
- Optional **KMS** envelope encryption for secrets.

---

## ✅ Prerequisites

- Terraform **1.5.x**
- AWS account with permissions to create VPC, EKS, IAM, KMS, ELB, EC2
- AWS CLI configured (`aws sts get-caller-identity`)
- `kubectl` matching your EKS minor version
- (Optional) `helm` for local troubleshooting
- Remote state backend (**S3 + DynamoDB** table) created or enabled via variables

---

## ⚙️ Quick Start

```bash
# 1) Clone
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>/env/dev

# 2) (Optional) Initialize pre-commit hooks
pre-commit install

# 3) Initialize Terraform
terraform init

# 4) Review plan
terraform plan -out tfplan

# 5) Apply
terraform apply tfplan

# 6) Update kubeconfig
aws eks update-kubeconfig --name <cluster_name> --region <aws_region>

# 7) Verify
kubectl get nodes -o wide
kubectl -n kube-system get ds aws-node -o yaml | grep -E 'ENABLE_PREFIX_DELEGATION|CUSTOM_NETWORK'
```

---

## 🧪 Example: Version Pinning (Terraform)

```hcl
# env/dev/versions.tf
terraform {
  required_version = ">= 1.5.0, < 1.6.0"

  required_providers {
    aws        = { source = "hashicorp/aws",        version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.0" }
  }
}
```

```hcl
# env/dev/variables.tf (snippets)
variable "cluster_name"       { type = string  default = "eks-ref" }
variable "region"             { type = string  default = "ap-south-1" }
variable "kubernetes_version" { type = string  default = "1.29" } # EKS

# Add-on versions (examples; adjust per EKS release notes)
variable "addon_versions" {
  type = object({
    vpc_cni    = string
    core_dns   = string
    kube_proxy = string
  })
  default = {
    vpc_cni    = "auto"   # or explicit, e.g., "v1.18.1-eksbuild.3"
    core_dns   = "auto"   # e.g., "v1.11.1-eksbuild.1"
    kube_proxy = "auto"   # e.g., "v1.29.0-eksbuild.1"
  }
}
```

---

## 🔌 Switching Pod IP Modes

**Mode A — AWS VPC CNI (default)**
- Enable **custom networking** & **prefix delegation** via module variables:
  - `enable_cni_custom_networking = true`
  - `enable_prefix_delegation = true`
- Provide per-AZ **pod subnets** (can be secondary CIDRs).
- The module creates `ENIConfig` objects named after AZs (e.g., `ap-south-1a`).

**Mode B — Overlay (Cilium)**
- Set `enable_cilium_overlay = true`
- Configure:
  - `cluster_pool_cidr = "10.244.0.0/16"`
  - `tunnel_protocol = "geneve"` (or `vxlan`)
- Note: you’ll use **CiliumNetworkPolicy** for pod-level policy instead of SG for pods.

---

## 📊 Outputs

- VPC ID, subnets (public/private), route table IDs
- EKS cluster name/ARN, OIDC provider, kubeconfig data
- Node Group names/ASG info
- Add-on statuses and Helm release outputs (if enabled)
- Security group IDs for common use

---

## 🔐 IAM & Access

- **IRSA** is enabled by default for add-ons that need AWS access (e.g., EBS CSI).
- Bastion login: either **SSM Session Manager** or SSH with restricted Source IPs.
- `aws-auth` configmap managed via Terraform (map roles/users).

---

## 💰 Cost Considerations

- **NAT Gateways**: 1 per AZ for HA (reduce to 1 total for dev if you accept AZ blast radius).
- **Data transfer** via NAT for egress from private subnets.
- Node sizes and count: right-size with Cluster Autoscaler/Karpenter.
- Use **prefix delegation** to improve pod density per node (fewer nodes).

---

## 🧩 Extending The Stack

Common add-ons you can toggle via variables:
- **Ingress**: AWS Load Balancer Controller (ALB), NGINX, or Gateway API
- **Storage**: EBS/EFS CSI drivers
- **Autoscaling**: Cluster Autoscaler or **Karpenter**
- **Observability**: CloudWatch, Prometheus/Grafana, OpenTelemetry
- **Policy**: Kyverno or OPA Gatekeeper

---

## 🗂️ Remote State (Recommended)

Use **S3 + DynamoDB** for state & locking. Example variables:

```hcl
# env/dev/backend.tf (optional pattern)
terraform {
  backend "s3" {
    bucket         = "<your-tf-state-bucket>"
    key            = "eks-ref/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "<your-lock-table>"
    encrypt        = true
  }
}
```

---

## 🧭 Roadmap

- [ ] Optional IPv6 / dual-stack mode  
- [ ] Blue/Green node group cutovers  
- [ ] PrivateLink-only clusters (no IGW)  
- [ ] End-to-end examples (ALB Ingress, EBS/EFS CSI)

---

## 🤝 Contributing

We welcome **features**, **bug fixes**, and **quick fixes**. This repo uses a **3-branch flow**:

- **dev** – active development (default target for community PRs)
- **UAT** – staging for integration testing and pre‑release validation
- **main** – production, tagged releases only

### 1) Fork & local setup
```bash
# Fork this repo on GitHub first, then clone your fork
git clone https://github.com/<your-username>/eks-without-ip-limit.git
cd eks-without-ip-limit

# Point "upstream" to the original repo so you can sync later
git remote add upstream https://github.com/bibin-skaria/eks-without-ip-limit.git
git fetch upstream
```

### 2) Create a topic branch from `dev`
Use a clear slug and Conventional Commits in your messages.
```bash
git checkout -b feature/<short-slug> upstream/dev
# or: fix/<short-slug>   | docs/<short-slug>   | chore/<short-slug>
```

### 3) Develop
- Keep changes focused and small.
- Update/add examples and docs when needed.
- Run local checks:
```bash
pre-commit install
make fmt
terraform -chdir=env/dev validate
# optional (but encouraged)
# tflint
# checkov -d .
```

### 4) Commit & push
```bash
git add -A
git commit -m "feat(network): add secondary CIDR for pod subnets"
git push -u origin feature/<short-slug>
```

### 5) Open a Pull Request
- **Target branch:** `dev` for all community contributions.
- Use the PR template. Describe the problem, the approach, and any version bumps.
- Attach evidence where helpful (e.g., `terraform plan` output, screenshots).
- CI checks must pass before review.

### 6) Reviews & merge
- Maintainers will review and request changes if needed.
- We squash‑merge into `dev` for a clean history.
- After merge, **sync your fork**:
```bash
git fetch upstream
git checkout dev
git reset --hard upstream/dev
git push origin dev --force-with-lease
```

---

### Branching & release flow (maintainers)
- **dev → UAT:** release PR for end‑to‑end testing (may create a `release/x.y.z` branch).
- **UAT → main:** final approval, tag, and publish.
```bash
# example tagging (maintainers)
git checkout main
git pull --ff-only
git tag -a vX.Y.Z -m "release: vX.Y.Z"
git push origin vX.Y.Z
```
- **Hotfixes:** create `hotfix/<slug>` from `main`, PR back to `main`, then **cherry‑pick** to `dev` to keep branches aligned.

---

### Issue types
Use the built‑in templates when opening issues:
- **Bug report** – steps to reproduce, expected vs actual
- **Feature request** – problem statement & proposal
- **Quick fix** – small improvements (docs, typos, defaults)

Thanks for contributing! 🙌

## 📜 License

This project is released under the **MIT License** (see `LICENSE`).  
If you prefer **dual-licensing (MIT or Apache-2.0)** for downstream users, open an issue—we can add `LICENSE-MIT` and `LICENSE-APACHE` and document the choice.

---

## ❓FAQ

**Q: Can I use smaller CIDRs?**  
A: Yes, but for stability use a large VPC (e.g., `/16`) and carve per-AZ subnets for **nodes** and **pods** separately if using custom networking.

**Q: How do I update EKS/add-on versions safely?**  
A: Bump the variables in `env/*/terraform.tfvars`, run `terraform plan`, review changes, then `apply`. Update this README’s **Versions** table in your PR.

**Q: Can I run public nodes?**  
A: Possible but not recommended. Keep nodes private; expose only through ELB/NLB.

---

### Maintainers

- Total Cloud Control — PR reviews & releases

### Donation

[![Sponsor on Open Collective](https://opencollective.com/eks-without-ip-limit/tiers/backer/badge.svg)](https://opencollective.com/eks-without-ip-limit)
