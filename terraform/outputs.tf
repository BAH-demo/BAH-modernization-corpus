###############################################################################
# EKS Cluster Outputs
###############################################################################

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64-encoded certificate data for cluster authentication"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "kubeconfig" {
  description = "kubectl config command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

###############################################################################
# VPC Outputs
###############################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "database_subnet_ids" {
  description = "IDs of database subnets"
  value       = aws_subnet.database[*].id
}

###############################################################################
# RDS Outputs
###############################################################################

output "rds_endpoints" {
  description = "RDS instance endpoints by system"
  value = {
    ofbiz        = aws_db_instance.ofbiz.endpoint
    odoo         = aws_db_instance.odoo.endpoint
    alfresco     = aws_db_instance.alfresco.endpoint
    nuxeo        = aws_db_instance.nuxeo.endpoint
    django_oscar = aws_db_instance.django_oscar.endpoint
    umbraco      = aws_db_instance.umbraco.endpoint
  }
}

###############################################################################
# S3 Outputs
###############################################################################

output "s3_bucket_arns" {
  description = "ARNs of S3 buckets by purpose"
  value = {
    artifacts        = aws_s3_bucket.artifacts.arn
    alfresco_content = aws_s3_bucket.alfresco_content.arn
    nuxeo_binaries   = aws_s3_bucket.nuxeo_binaries.arn
    nastran_data     = aws_s3_bucket.nastran_data.arn
    logs             = aws_s3_bucket.logs.arn
  }
}

###############################################################################
# Node Group Outputs
###############################################################################

output "node_group_default" {
  description = "Default node group name"
  value       = aws_eks_node_group.default.node_group_name
}

output "node_group_compute" {
  description = "Compute node group name (for NASTRAN-95)"
  value       = aws_eks_node_group.compute.node_group_name
}
