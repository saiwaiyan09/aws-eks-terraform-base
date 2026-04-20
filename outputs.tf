# =============================================================================
# VPC
# =============================================================================

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

# =============================================================================
# Subnets
# =============================================================================

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (where worker nodes run)."
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# =============================================================================
# NAT Gateway
# =============================================================================

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway."
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "The public Elastic IP address associated with the NAT Gateway."
  value       = aws_eip.nat.public_ip
}

# =============================================================================
# EKS Cluster
# =============================================================================

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "The API server endpoint URL for the EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version running on the EKS cluster."
  value       = aws_eks_cluster.main.version
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.main.arn
}

output "cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the cluster (used for kubeconfig)."
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer" {
  description = "The OIDC issuer URL of the EKS cluster (required for IAM Roles for Service Accounts)."
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# =============================================================================
# EKS Node Group
# =============================================================================

output "node_group_name" {
  description = "The name of the EKS managed node group."
  value       = aws_eks_node_group.main.node_group_name
}

output "node_group_status" {
  description = "The current status of the EKS managed node group."
  value       = aws_eks_node_group.main.status
}

output "node_group_instance_types" {
  description = "EC2 instance types used by the node group."
  value       = aws_eks_node_group.main.instance_types
}

# =============================================================================
# IAM Roles
# =============================================================================

output "cluster_iam_role_arn" {
  description = "The ARN of the IAM role used by the EKS cluster control plane."
  value       = aws_iam_role.eks_cluster.arn
}

output "node_iam_role_arn" {
  description = "The ARN of the IAM role used by the EKS worker nodes."
  value       = aws_iam_role.eks_node.arn
}

# =============================================================================
# kubeconfig helper
# =============================================================================

output "kubeconfig_command" {
  description = "Run this command to update your local kubeconfig for the cluster."
  value       = "aws eks update-kubeconfig --region ${aws_eks_cluster.main.arn != "" ? var.aws_region : var.aws_region} --name ${aws_eks_cluster.main.name} --profile ${var.profile}"
}
