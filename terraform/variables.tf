###############################################################################
# General
###############################################################################

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "legacy-modernization"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "legacy-modernization"
    ManagedBy   = "terraform"
    Environment = "production"
    Agency      = "federal"
  }
}

###############################################################################
# VPC
###############################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

###############################################################################
# EKS Cluster
###############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "legacy-modernization-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API server endpoint is publicly accessible"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Whether the EKS API server endpoint is accessible within the VPC"
  type        = bool
  default     = true
}

###############################################################################
# EKS Node Groups
###############################################################################

variable "node_instance_types" {
  description = "EC2 instance types for the default node group"
  type        = list(string)
  default     = ["m6i.2xlarge"]
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the default node group"
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the default node group"
  type        = number
  default     = 20
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
  default     = 6
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 100
}

variable "compute_instance_types" {
  description = "EC2 instance types for the compute-intensive node group (NASTRAN)"
  type        = list(string)
  default     = ["c6i.4xlarge"]
}

variable "compute_node_min_size" {
  description = "Minimum number of nodes in the compute node group"
  type        = number
  default     = 0
}

variable "compute_node_max_size" {
  description = "Maximum number of nodes in the compute node group"
  type        = number
  default     = 5
}

variable "compute_node_desired_size" {
  description = "Desired number of nodes in the compute node group"
  type        = number
  default     = 0
}

###############################################################################
# RDS
###############################################################################

variable "rds_instance_class" {
  description = "RDS instance class for application databases"
  type        = string
  default     = "db.r6g.large"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GiB for RDS instances"
  type        = number
  default     = 100
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage in GiB for RDS autoscaling"
  type        = number
  default     = 500
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 30
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS instances"
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS instances"
  type        = bool
  default     = true
}

###############################################################################
# S3
###############################################################################

variable "s3_force_destroy" {
  description = "Allow destruction of S3 buckets with objects (use false in production)"
  type        = bool
  default     = false
}
