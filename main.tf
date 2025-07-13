###############################
# Terraform Cloud OIDC Role Setup
# One-Step Infra to enable secure role assumption
###############################
provider "aws" {
  region = "ap-south-1"
}

########################
# 1. OIDC Identity Provider for Terraform Cloud
########################
resource "aws_iam_openid_connect_provider" "tfc" {
  url             = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd8e9e4"]
}

########################
# 2. IAM Role for TFC Workspace
########################
resource "aws_iam_role" "tfc_execution_role" {
  name = "tfc-eks-execution-role"

assume_role_policy = jsonencode({
  Version = "2012-10-17",
  Statement = [
    {
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.tfc.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringLike = {
          "app.terraform.io:sub" = "organization:your-org-name:*"
        }
      }
    }
  ]
})
}

########################
# 3. IAM Policy Attachments (Adjust based on what services you want)
########################
resource "aws_iam_role_policy_attachment" "eks_access" {
  role       = aws_iam_role.tfc_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.tfc_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.tfc_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "msk_access" {
  role       = aws_iam_role.tfc_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonMSKFullAccess"
}

resource "aws_iam_role_policy_attachment" "r53_access" {
  role       = aws_iam_role.tfc_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

########################
# OUTPUT
########################
output "tfc_execution_role_arn" {
  value = aws_iam_role.tfc_execution_role.arn
  description = "Use this ARN in Terraform Cloud workspace to assume this role."
}
