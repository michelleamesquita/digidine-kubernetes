variable "vpc_cidr_block" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}

variable "cluster_identifier" {
  description = "Identifier for the DocumentDB cluster"
  type        = string
}

variable "master_username" {
  description = "Master username for the DocumentDB cluster"
  type        = string
}

variable "master_password" {
  description = "Master password for the DocumentDB cluster"
  type        = string
}

variable "subnet_group_name" {
  description = "Name of the DocumentDB subnet group"
  type        = string
}

variable "security_group_name" {
  description = "Name of the security group for DocumentDB"
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks for ingress rules"
  type        = list(string)
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks for egress rules"
  type        = list(string)
}