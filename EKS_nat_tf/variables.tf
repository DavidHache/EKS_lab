variable "region" {
  default     = "us-east-1"
  type        = string
  description = "Region of the VPC"
}


variable "cidr_block_default" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_blocks_default" {
  default     = ["10.0.0.0/24", "10.0.2.0/24"]
  type        = list(any)
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks_default" {
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
  type        = list(any)
  description = "List of private subnet CIDR blocks"
}

variable "cidr_block_eks" {
  default     = "192.168.0.0/24"
  type        = string
  description = "CIDR block for the VPC"
}

variable "private_subnet_cidr_blocks_eks" {
  default     = ["192.168.0.0/25", "192.168.0.128/25"]
  type        = list(any)
  description = "List of private subnet CIDR blocks"
}

variable "availability_zones" {
  default     = ["us-east-1a", "us-east-1b"]
  type        = list(any)
  description = "List of availability zones"
}

variable "eks_cluster_name" {
  default     = "EKS1"
  type        = string
  description = "Name of the EKS cluster"
}

variable "eks_cluster_version" {
  default     = "1.18"
  type        = string
  description = "Kubernetes version"
}