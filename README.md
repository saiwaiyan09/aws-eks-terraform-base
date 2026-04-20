# 🚀 AWS EKS Production Cluster via Terraform

> Provision a **production-grade Amazon EKS cluster** on a fully custom VPC using raw AWS provider resources — no third-party modules, maximum transparency and control.

This repository provisions the complete foundational infrastructure for running containerised workloads on Kubernetes in AWS:

- ✅ **Custom VPC** with public and private subnet tiers across two Availability Zones
- ✅ **EKS Control Plane** (Kubernetes 1.33) with a public API endpoint
- ✅ **Managed Node Group** — worker nodes running exclusively in private subnets
- ✅ **IAM roles** for both the control plane and worker nodes, following least-privilege principles
- ✅ **OIDC provider** pre-configured for IAM Roles for Service Accounts (IRSA)

---

## 🏗️ Architecture Overview

```
                          ┌───────────────────────────────────────────────┐
                          │               VPC (192.168.0.0/16)            │
                          │                                               │
  Internet ──► IGW ──►    │  ┌───────────────────┐  ┌───────────────────┐ │
                          │  │  Public Subnet 1  │  │  Public Subnet 2  │ │
                          │  │  192.168.1.0/24   │  │  192.168.2.0/24   │ │
                          │  │  (AZ-a)           │  │  (AZ-b)           │ │
                          │  │  [NAT Gateway]    │  │                   │ │
                          │  └────────┬──────────┘  └───────────────────┘ │
                          │           │ (outbound only)                   │
                          │  ┌────────▼──────────┐  ┌───────────────────┐ │
                          │  │  Private Subnet 1 │  │  Private Subnet 2 │ │
                          │  │  192.168.11.0/24  │  │  192.168.12.0/24  │ │
                          │  │  (AZ-a)           │  │  (AZ-b)           │ │
                          │  │  [Worker Nodes]   │  │  [Worker Nodes]   │ │
                          │  └───────────────────┘  └───────────────────┘ │
                          └───────────────────────────────────────────────┘
                                          ▲
                              kubectl ────┘ (via public EKS endpoint)
```

| Design Decision | Rationale |
|---|---|
| Worker nodes in **private subnets** | Nodes are never directly reachable from the internet |
| **NAT Gateway** in Public Subnet 1 | Nodes can pull images and reach AWS APIs without inbound exposure |
| **Public EKS endpoint** | Allows `kubectl` access from developer machines and CI/CD runners |
| **Two AZs** for all subnet tiers | High availability — workloads survive a single AZ failure |

---

## 🛠️ Prerequisites

Ensure the following tools are installed and configured on your local machine before proceeding.

| Tool | Minimum Version | Install Guide |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | `>= 1.6.0` | `brew install terraform` |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | `>= 2.x` | `brew install awscli` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `>= 1.28` | `brew install kubectl` |
| [Helm](https://helm.sh/docs/intro/install/) | `>= 3.x` | `brew install helm` |


```bash

```

---

## ⚡ Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/<your-org>/aws-eks-terraform-base.git
cd aws-eks-terraform-base
```

### 2. Review and customise variables

Open `terraform.tfvars` and confirm or adjust the values for your environment:

```

### 3. Initialise Terraform

Downloads the AWS provider and sets up the backend.

```bash
terraform init
```

### 4. Review the execution plan

```bash
terraform plan
```

Inspect the plan output carefully. Expect **~15–20 resources** to be created.

### 5. Apply the configuration

```bash
terraform apply
```

Type `yes` when prompted. Cluster provisioning typically takes **10–15 minutes**.

### 6. Configure `kubectl`

Once `apply` completes, update your local kubeconfig to point at the new cluster:

```bash
aws eks update-kubeconfig \
  --region ap-southeast-7 \
  --name hc-eks-thai-cluster \
  --profile master-console-admin
```

### 7. Verify cluster access

```bash
kubectl get nodes
kubectl get pods -A
```

All nodes should reach `Ready` status within a few minutes of the apply completing.

---

## 📁 Project Structure

```
aws-eks-terraform-base/
├── versions.tf          # Terraform and AWS provider version constraints; AWS provider block
├── variables.tf         # All input variable declarations (types + descriptions)
├── terraform.tfvars     # Concrete values for every variable (your environment config)
├── network.tf           # VPC, subnets, IGW, NAT Gateway, EIPs, and route tables
├── cluster.tf           # EKS control plane, cluster IAM role, and policy attachments
├── nodes.tf             # Managed node group, node IAM role, and policy attachments
├── iam_lbc.tf           # OIDC identity provider + IAM role for AWS Load Balancer Controller
└── outputs.tf           # Key outputs: cluster endpoint, subnet IDs, kubeconfig command, etc.
```

---

## 🔌 Next Steps — Add-ons

The cluster is immediately ready for production add-ons. The most critical first step for exposing services via `Ingress` or `LoadBalancer` is the **AWS Load Balancer Controller**.

### AWS Load Balancer Controller

The OIDC provider and the dedicated IAM role are already provisioned by `iam_lbc.tf`.  
Install the controller via Helm:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=hc-eks-thai-cluster \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<LBC_IAM_ROLE_ARN>
```

> 💡 Retrieve the LBC IAM role ARN from Terraform outputs:
> ```bash
> terraform output
> ```

Other recommended add-ons to layer in next:

- **Cluster Autoscaler** — automatic node scaling based on pending pods
- **Metrics Server** — required for `kubectl top` and HorizontalPodAutoscaler
- **ExternalDNS** — automatic Route 53 DNS record management from Ingress resources
- **Karpenter** — next-generation node provisioning (alternative to Cluster Autoscaler)

---

## 🧹 Clean Up / Teardown

> [!CAUTION]
> **READ THIS ENTIRE SECTION BEFORE RUNNING `terraform destroy`.**
>
> Terraform **cannot** delete a VPC or subnets that still have AWS resources attached to them.
> If you have deployed Kubernetes `Service` objects of `type: LoadBalancer` or `Ingress` resources
> backed by the AWS Load Balancer Controller, AWS will have automatically created **Classic / Network / Application Load Balancers** and associated **Security Groups** that are **not managed by Terraform**.
>
> Running `terraform destroy` without cleaning these up first **will cause the destroy to fail**
> and may leave orphaned, billable AWS resources in your account.

### Step 1 — Delete all Kubernetes LoadBalancer services and Ingresses

```bash
# List all LoadBalancer-type services across all namespaces
kubectl get svc -A --field-selector spec.type=LoadBalancer

# Delete them individually, e.g.:
kubectl delete svc <service-name> -n <namespace>

# List all Ingress resources
kubectl get ingress -A

# Delete them individually, e.g.:
kubectl delete ingress <ingress-name> -n <namespace>
```

Wait for the Load Balancers to be fully de-provisioned in the AWS console before continuing.

### Step 2 — Destroy all Terraform-managed resources

```bash
terraform destroy
```

Type `yes` when prompted. This will permanently delete:
- The EKS cluster and all worker nodes
- All VPC networking resources (subnets, NAT Gateway, IGW, route tables)
- All IAM roles and policy attachments created by this configuration

> ⚠️ The NAT Gateway Elastic IP incurs charges per hour even when not attached. Verify it has been released in the **EC2 → Elastic IPs** console after destroy completes.

---

