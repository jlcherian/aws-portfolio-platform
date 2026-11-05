variable "name" {
  description = "Prefix for resource names, e.g. portfolio-dev"
  type        = string
}

variable "vpc_id" {
  description = "VPC to build in (from the network module)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the database"
  type        = list(string)
}

variable "web_sg_id" {
  description = "Web servers' security group, the only thing allowed to connect"
  type        = string
}

variable "multi_az" {
  description = "Keep a standby copy in a second AZ"
  type        = bool
  default     = false
}