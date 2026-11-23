variable "name" {
  description = "Prefix for resource names, e.g. portfolio-dev"
  type        = string
}

variable "vpc_id" {
  description = "VPC to build in (from the network module)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the containers"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Load balancer's security group, the only thing allowed to reach the containers"
  type        = string
}

variable "listener_arn" {
  description = "Load balancer listener to attach the container routing rule to"
  type        = string
}

variable "image" {
  description = "Full ECR image address, including the tag"
  type        = string
}

variable "container_port" {
  description = "Port the app listens on inside the container"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "How many copies of the container to run"
  type        = number
  default     = 2
}