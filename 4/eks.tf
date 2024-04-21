data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "external_dns_policy" {
  name        = "${var.ClusterBaseName}ExternalDNSPolicy"
  description = "Policy for allowing ExternalDNS to modify Route 53 records"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource": [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource": [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_policy_attach" {
  role       = "${var.ClusterBaseName}-node-group-eks-node-group"
  policy_arn = aws_iam_policy.external_dns_policy.arn

  depends_on = [module.eks]
}

resource "aws_security_group" "node_group_sg" {
  name        = "${var.ClusterBaseName}-node-group-sg"
  description = "Security group for EKS Node Group"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.ClusterBaseName}-node-group-sg"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>20.0"

  cluster_name = var.ClusterBaseName
  cluster_version = var.KubernetesVersion
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id = module.vpc.vpc_id
  enable_irsa = true
  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    default = {
      name             = "${var.ClusterBaseName}-node-group"
      use_name_prefix  = false
      instance_type    = var.WorkerNodeInstanceType
      desired_size     = var.WorkerNodeCount
      max_size         = var.WorkerNodeCount + 2
      min_size         = var.WorkerNodeCount - 1
      disk_size        = var.WorkerNodeVolumesize
      subnets          = module.vpc.public_subnets
      key_name         = var.KeyName
      vpc_security_group_ids = [aws_security_group.node_group_sg.id]
      iam_role_name    = "${var.ClusterBaseName}-node-group-eks-node-group"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        "${var.ClusterBaseName}ExternalDNSPolicy" = aws_iam_policy.external_dns_policy.arn
      }
   }
  }

  access_entries = {
    admin = {
      kubernetes_groups = []
      principal_arn     = "${data.aws_caller_identity.current.arn}"

      policy_associations = {
        myeks = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = "${var.ClusterBaseName}-lab"
    Terraform   = "true"
  }
}
