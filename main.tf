terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.41"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = var.aws_region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true

  endpoints {
    sqs      = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
    ec2      = var.localstack_endpoint
    s3       = var.localstack_endpoint
    sts      = var.localstack_endpoint
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubernetes_context
}

locals {
  common_tags = {
    Environment = "local"
    ManagedBy   = "terraform"
    Project     = "local-infra-project"
  }
}

resource "aws_sqs_queue" "codex_responses" {
  name                              = "codex-ai-responses"
  kms_master_key_id                 = "alias/aws/sqs" # הצפנת נתונים במנוחה
  kms_data_key_reuse_period_seconds = 300

  tags = local.common_tags
}

# באקט S3 מעודכן עם פוליסי אבטחה מלא
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = merge(local.common_tags, {
    Name = "local-terraform-state"
  })

  # החריגות של צ'קוב לדברים שלא רלוונטיים לסביבה מקומית:
  # checkov:skip=CKV_AWS_144: Cross Region Replication is not required for local infra
  # checkov:skip=CKV_AWS_18: Access logging is not required for local state bucket
  # checkov:skip=CKV2_AWS_62: Event notifications not required for local deployment
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not required for local development
}

# הפעלת Versioning על ה-S3
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# הצפנת באקט ה-S3 כברירת מחדל
resource "aws_s3_bucket_server_side_encryption_configuration" "state_crypto" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# חסימה מוחלטת של גישה ציבורית לבאקט ה-S3
resource "aws_s3_bucket_public_access_block" "state_privacy" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  count        = var.enable_dynamodb_lock_table ? 1 : 0
  name         = var.state_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name = "local-terraform-locks"
  })
}

module "network" {
  source = "./modules/network"

  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
}

module "compute" {
  source = "./modules/compute"

  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id
  instance_type    = var.instance_type
}

module "kubernetes" {
  count  = var.enable_kubernetes ? 1 : 0
  source = "./modules/kubernetes"
}

output "localstack_endpoint" {
  description = "LocalStack API endpoint for local AWS-compatible development."
  value       = var.localstack_endpoint
}

output "state_bucket_name" {
  description = "S3 bucket used for local Terraform state experiments."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_lock_table_name" {
  description = "DynamoDB table used for local Terraform lock experiments."
  value       = var.enable_dynamodb_lock_table ? aws_dynamodb_table.terraform_locks[0].name : null
}

output "web_instance_public_ip" {
  description = "Public IP reported by the local EC2-compatible instance resource."
  value       = module.compute.server_ip
}

output "local_service_urls" {
  description = "Useful local URLs for the demo platform."
  value = {
    grafana    = "http://127.0.0.1:3030"
    kubernetes = "http://localhost:30080"
    localstack = var.localstack_endpoint
    prometheus = "http://127.0.0.1:9090"
    web        = "http://127.0.0.1:8080"
  }
}

output "kubernetes_namespace" {
  description = "Namespace created for local Kubernetes workloads."
  value       = var.enable_kubernetes ? module.kubernetes[0].namespace_name : null
}

output "kubernetes_service_name" {
  description = "Service name exposed by the local Kubernetes module."
  value       = var.enable_kubernetes ? module.kubernetes[0].service_name : null
}
