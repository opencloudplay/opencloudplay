variable "region" {
  description = "The AWS region to deploy resources in"
  default     = "eu-central-1"
}

variable "zone" {
  description = "The availability zone within the region"
  default     = "eu-central-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.11.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  default     = "10.11.22.0/24"
}

variable "ami" {
  description = "AMI ID for the instance"
  default     = "ami-0ced908879ca69797" # Example: Windows Server 2022 Base
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  default     = "g4dn.xlarge"
}

variable "namespace" {
  description = "Version for tagging resources"
  default     = "1"
}
