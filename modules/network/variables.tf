variable "name" {
  description = "Prefix for resource names, e.g. portfolio-dev"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the whole VPC"
  type        = string
  default     = "10.0.0.0/16"
}