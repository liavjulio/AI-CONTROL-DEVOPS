variable "vpc_id" {
  description = "ID of the VPC where the compute node will be created."
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet where the compute node will be created."
  type        = string
}

#variable "instance_type" {
#  description = "Instance type for the local EC2-compatible instance."
#  type        = string
#  default     = "t2.micro"
#}
