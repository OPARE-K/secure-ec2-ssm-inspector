variable "project_name" {
  type    = string
  default = "secure-ec2-ssm-inspector"
}

variable "region" {
  type    = string
  default = "eu-west-2" # London
}

variable "az_a" {
  type    = string
  default = "eu-west-2a"
}

variable "az_b" {
  type    = string
  default = "eu-west-2b"
}

variable "cidr_vpc" {
  type    = string
  default = "10.60.0.0/16"
}

variable "cidr_public_a" {
  type    = string
  default = "10.60.10.0/24"
}

variable "cidr_public_b" {
  type    = string
  default = "10.60.11.0/24"
}

variable "cidr_private_a" {
  type    = string
  default = "10.60.20.0/24"
}
