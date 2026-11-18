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

## CI/CD pipeline (GitHub Actions + OIDC)

Every change to this repo goes through a pull request. Nobody runs `terraform apply` from a laptop.

```
branch → PR → Terraform Plan (fmt, validate, Checkov, plan → PR comment)
       → merge to main (blocked until plan passes)
       → Terraform Apply (pauses for approval on the dev environment)
       → AWS
```

| Workflow | Trigger | What it does |
|---|---|---|
| `terraform-plan.yml` | Pull request to `main` | Logs in to AWS via OIDC, checks formatting, validates, runs a Checkov security scan, and posts the Terraform plan as a PR comment |
| `terraform-apply.yml` | Merge to `main` touching `envs/dev/` or `modules/`, or the manual **Run workflow** button | Waits for a required reviewer, then applies (or destroys) the dev environment |

**Security choices**

- **No stored AWS keys.** GitHub Actions assumes the `github-actions-terraform` IAM role through OIDC and gets short-lived credentials for each run (`global/github-oidc.tf`).
- **Locked-down trust policy.** The role trusts only tokens for `sts.amazonaws.com` from this repository, matched by GitHub's owner and repo IDs, so a deleted-and-recreated repo with the same name can't assume it.
- **Branch protection on `main`.** Changes need a pull request, and the `plan` check must pass before merging. No bypassing.
- **Approval gate.** The `dev` environment requires a reviewer and only accepts deployments from `main`.
- **One apply at a time.** A `concurrency` group stops two applies from colliding on the same state.
- **Known tradeoff:** the pipeline role uses `AdministratorAccess` to keep the portfolio simple. In production I'd scope it to only the services Terraform manages (least privilege).

**Account-wide resources** live in `global/` with their own state key (`global/terraform.tfstate`), so tearing down dev never removes the OIDC role the pipeline needs.