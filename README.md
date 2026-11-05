# aws-portfolio-platform

A highly available web application on AWS, built entirely with Terraform. Containers (ECS) and a GitHub Actions pipeline are coming in later phases.

## What this builds

- **VPC** across 2 Availability Zones, with public and private subnets
- **Internet gateway** for public traffic and a **NAT gateway** so private servers can reach out without being reachable
- **Application Load Balancer** in the public subnets, the only internet-facing entry point
- **Auto Scaling group** of EC2 web servers (min 2, max 4) in the private subnets, scaling on CPU
- **RDS MySQL** in the private subnets, with the password generated and stored in Secrets Manager
- **Security group chaining**: internet → ALB → web servers → database, each layer only trusting the one in front

## Architecture

    Internet
       |
    [ ALB ]                  public subnets (us-east-1a, us-east-1b)
       |
    [ EC2 ] [ EC2 ]          private subnets, Auto Scaling 2-4
       |
    [ RDS MySQL ]            private subnets

## Repo layout

| Folder | Purpose |
| --- | --- |
| `bootstrap/` | Creates the S3 bucket that stores Terraform state (run once) |
| `modules/network` | VPC, subnets, gateways, route tables |
| `modules/compute` | ALB, launch template, Auto Scaling group |
| `modules/database` | RDS MySQL, subnet group, security group |
| `envs/dev` | Wires the modules together for the dev environment |

## Proof it works

The load balancer spreads traffic across both Availability Zones:

IMAGE-LINE-A
IMAGE-LINE-B

## How to deploy

    cd envs/dev
    terraform init
    terraform plan
    terraform apply
    terraform destroy   # when finished, to avoid charges

## Tagging standard

Every resource is tagged with:

| Key | Value |
| --- | --- |
| Project | aws-portfolio-platform |
| Environment | dev or prod |
| Owner | joel |