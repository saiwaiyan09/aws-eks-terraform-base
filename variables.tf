variable "profile" {
  description = "The AWS profile to use for authentication."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy all resources into."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnet_1_cidr" {
  description = "The CIDR block for public subnet 1."
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "The CIDR block for public subnet 2."
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "The CIDR block for private subnet 1."
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "The CIDR block for private subnet 2."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "node_group_name" {
  description = "The name of the EKS managed node group."
  type        = string
}

variable "instance_types" {
  description = "A list of EC2 instance types for the EKS managed node group."
  type        = list(string)
}
