variable "name" {
  description = "Prefix for resource names, e.g. portfolio-dev"
  type        = string
}

variable "vpc_id" {
  description = "VPC to build in (from the network module)"
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets for the load balancer"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subnets for the web servers"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 size for the web servers"
  type        = string
  default     = "t3.micro"
}