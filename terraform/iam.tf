###############################################################################
# EKS Cluster IAM Role
###############################################################################

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

###############################################################################
# EKS Node Group IAM Role
###############################################################################

resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

###############################################################################
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
###############################################################################

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-oidc"
  }
}

###############################################################################
# Service Account IAM Roles (IRSA) - per system
###############################################################################

locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
  oidc_issuer       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")

  # Systems that need S3 access
  s3_systems = {
    "alfresco-community" = aws_s3_bucket.alfresco_content.arn
    "nuxeo"              = aws_s3_bucket.nuxeo_binaries.arn
    "nastran-95"         = aws_s3_bucket.nastran_data.arn
  }

  # All web-service systems
  all_systems = [
    "apache-ofbiz", "odoo", "alfresco-community", "nuxeo",
    "django-oscar", "umbraco-cms", "mezzanine", "b2cweb",
    "dfe-net", "monolith-enterprise", "cfwheels",
  ]
}

resource "aws_iam_role" "service_account" {
  for_each = toset(local.all_systems)

  name = "${var.cluster_name}-${each.key}-sa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${local.oidc_issuer}:sub" = "system:serviceaccount:legacy-modernization:${each.key}"
            "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name   = "${var.cluster_name}-${each.key}-sa"
    System = each.key
  }
}

###############################################################################
# S3 Access Policies for systems that need object storage
###############################################################################

resource "aws_iam_role_policy" "s3_access" {
  for_each = local.s3_systems

  name = "${var.cluster_name}-${each.key}-s3"
  role = aws_iam_role.service_account[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = [
          each.value,
          "${each.value}/*",
        ]
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.s3.arn
      }
    ]
  })
}

###############################################################################
# Kubernetes Service Accounts
###############################################################################

resource "kubernetes_service_account" "systems" {
  for_each = toset(local.all_systems)

  metadata {
    name      = each.key
    namespace = "legacy-modernization"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.service_account[each.key].arn
    }
    labels = {
      app = each.key
    }
  }

  depends_on = [aws_eks_cluster.main]
}
