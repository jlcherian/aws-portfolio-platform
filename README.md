# aws-portfolio-platform

A highly available, containerized web application on AWS, built entirely with Terraform and deployed through GitHub Actions.

## What this builds

- **VPC** across 2 Availability Zones, with public and private subnets
- **Internet gateway** for public traffic and a **NAT gateway** so private resources can reach out without being reachable
- **Application Load Balancer** in the public subnets, the only internet-facing entry point
- **ECS Fargate service** running the app as containers (min 2, max 4) in the private subnets, scaling on CPU, with automatic rollback of failed deploys
- **ECR repository** for the app's Docker images, with vulnerability scanning on every push and a lifecycle policy that keeps the last 10 images
- **Auto Scaling group** of EC2 web servers (Phase 1), still built but no longer receiving traffic now that ECS handles it
- **RDS MySQL** in the private subnets, with the password generated and stored in Secrets Manager
- **Security group chaining**: internet → ALB → app → database, each layer only trusting the one in front

## Architecture

    Internet
       |
    [ ALB ]                      public subnets (us-east-1a, us-east-1b)
       |  listener rule: all paths → ECS target group
       |
    [ Fargate task ] [ Fargate task ]   private subnets, ECS service, autoscaling 2-4
       |
    [ RDS MySQL ]                private subnets

    GitHub Actions → ECR (image) → ECS (new task definition) → rolling deploy

## Repo layout

| Folder | Purpose |
| --- | --- |
| `bootstrap/` | Creates the S3 bucket that stores Terraform state (run once) |
| `global/` | Account-wide resources: GitHub OIDC role and the ECR repository |
| `app/` | Flask app and its Dockerfile |
| `modules/network` | VPC, subnets, gateways, route tables |
| `modules/compute` | ALB, launch template, Auto Scaling group |
| `modules/database` | RDS MySQL, subnet group, security group |
| `modules/ecs` | ECS cluster, task definition, service, target group, autoscaling, IAM roles, logs |
| `envs/dev` | Wires the modules together for the dev environment |
| `.github/workflows` | Terraform plan, Terraform apply, and app deploy pipelines |

## Proof it works

**Phase 1:** the load balancer spreads traffic across both Availability Zones:

[Response from the web server in us-east-1a](docs/images/hello-az-a.png)
[Response from the web server in us-east-1b](docs/images/hello-az-b.png)

**Phase 3:** the app running on ECS Fargate, deployed by the pipeline:

[App running on ECS Fargate](docs/images/ecs-app.png)

**Phase 3:** a deliberately broken deploy. The new containers crashed on startup, the ECS deployment circuit breaker stopped the rollout and rolled back automatically, and the site stayed up the whole time:

[ECS events showing the failed deployment and successful rollback](docs/images/ecs-rollback.png)

## How to deploy

Infrastructure changes go through pull requests (see the CI/CD section below). For a local run:

    cd envs/dev
    terraform init
    terraform plan
    terraform apply
    terraform destroy   # when finished, to avoid charges

## The app and its container

`app/` holds a small Flask app with a `/` page and a `/health` endpoint, served by gunicorn on port 8080.

The Dockerfile:

- Starts from `python:3.12-slim` to keep the image small
- Installs dependencies before copying the code, so Docker's layer cache skips the install when only the code changes
- Uses `pip install --no-cache-dir` so pip's download cache isn't baked into the image
- Runs as a non-root `appuser`, which limits the damage if the app were ever compromised
- Is built for `linux/amd64`, matching the x86 Fargate platform set in the task definition

## Running on ECS Fargate

| Piece | Setting | Why |
| --- | --- | --- |
| Task size | 0.25 vCPU, 512 MB | Smallest Fargate size, enough for this app |
| Networking | `awsvpc`, private subnets, no public IP | Each task gets its own IP and is only reachable through the ALB |
| Security group | Port 8080 only from the ALB's security group | Same least-privilege chaining as the EC2 tier |
| Target group | `target_type = "ip"`, health check on `/health` | The ALB routes straight to each container's IP |
| Desired count | 2, autoscaling 2-4 on 50% average CPU | Always one spare, never runaway costs |
| Circuit breaker | Enabled with rollback | A deploy that can't become healthy is rolled back automatically |
| Execution role | `AmazonECSTaskExecutionRolePolicy` | Lets ECS pull from ECR and write to CloudWatch Logs |
| Task role | No permissions | The app doesn't call AWS, so it gets nothing |
| Logs | CloudWatch Logs, 14-day retention | Crash output survives after a container is gone |

Terraform creates the service, then `lifecycle { ignore_changes = [task_definition, desired_count] }` hands those two settings over to the deploy pipeline and the autoscaler, so a later `terraform apply` never rolls back the app or undoes scaling.

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
Infrastructure:
branch → PR → Terraform Plan (fmt, validate, Checkov, plan → PR comment)
       → merge to main (blocked until plan passes)
       → Terraform Apply (pauses for approval on the dev environment)
       → AWS

Application:
change in app/ → PR → merge to main
       → App deploy (pauses for approval)
       → build image tagged with the commit SHA → push to ECR
       → new task definition revision → ECS rolling deploy
       → wait until the service is stable (fails if ECS rolls back)
```

| Workflow | Trigger | What it does |
|---|---|---|
| `terraform-plan.yml` | Pull request to `main` | Logs in to AWS via OIDC, checks formatting, validates, runs a Checkov security scan, and posts the Terraform plan as a PR comment |
| `terraform-apply.yml` | Merge to `main` touching `envs/dev/` or `modules/`, or the manual **Run workflow** button | Waits for a required reviewer, then applies (or destroys) the dev environment |
| `app-deploy.yml` | Merge to `main` touching `app/`, or the manual **Run workflow** button | Builds and pushes the image, renders a new task definition with it, and deploys it to ECS |

**Why images are tagged with the commit SHA:** every image is unique and traces back to the exact commit that built it, and rolling back means pointing ECS at an earlier tag. A moving `latest` tag would make both impossible.

**Security choices**

- **No stored AWS keys.** GitHub Actions assumes the `github-actions-terraform` IAM role through OIDC and gets short-lived credentials for each run (`global/github-oidc.tf`).
- **Locked-down trust policy.** The role trusts only tokens for `sts.amazonaws.com` from this repository, matched by GitHub's owner and repo IDs, so a deleted-and-recreated repo with the same name can't assume it.
- **Branch protection on `main`.** Changes need a pull request, and the `plan` check must pass before merging. No bypassing.
- **Approval gate.** The `dev` environment requires a reviewer and only accepts deployments from `main`.
- **One run at a time.** `concurrency` groups stop two applies, or two deploys, from colliding.
- **Image scanning.** ECR scans every pushed image for known vulnerabilities (CVEs).
- **Known tradeoff:** the pipeline role uses `AdministratorAccess` to keep the portfolio simple. In production I'd scope it to only the services Terraform and the deploy need (least privilege).

**Account-wide resources** live in `global/` with their own state key (`global/terraform.tfstate`), so tearing down dev never removes the OIDC role the pipeline needs or the images in ECR.

## What I'd do next

- Remove the Phase 1 EC2 Auto Scaling group now that ECS serves all traffic
- Add HTTPS with an ACM certificate and redirect HTTP to HTTPS
- Switch Fargate to ARM (Graviton) for about 20% lower cost, building the image for `linux/arm64`
- Scope the pipeline role down from `AdministratorAccess`