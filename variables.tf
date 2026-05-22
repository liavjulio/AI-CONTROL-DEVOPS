variable "aws_region" {
  description = "AWS region used by the LocalStack-backed AWS provider."
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "Base endpoint for the LocalStack edge API."
  type        = string
  default     = "http://127.0.0.1:4566"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket that stores local Terraform state artifacts."
  type        = string
  default     = "liav-terraform-state-bucket"
}

variable "state_lock_table_name" {
  description = "Name of the DynamoDB table used for local Terraform state locking."
  type        = string
  default     = "liav-terraform-lock-table"
}

variable "enable_dynamodb_lock_table" {
  description = "Whether to create a DynamoDB lock table in LocalStack. Disable by default because LocalStack can be inconsistent with Terraform waiters for this resource."
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "CIDR block for the local VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The vpc_cidr value must be a valid CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet in the local VPC."
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.public_subnet_cidr))
    error_message = "The public_subnet_cidr value must be a valid CIDR block."
  }
}

variable "instance_type" {
  description = "Instance type used for the simulated EC2 web node."
  type        = string
  default     = "t2.micro"
}

variable "enable_kubernetes" {
  description = "Whether to deploy the local Kubernetes nginx workload to the current kube context."
  type        = bool
  default     = true
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file Terraform should use."
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_context" {
  description = "Kubernetes context Terraform should target for local deployments."
  type        = string
  default     = "kind-liav-infra-cluster"
}
