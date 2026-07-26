# Automated CI/CD Pipeline on AWS

A production-style deployment pipeline: a push to `main` runs the tests, builds a
Docker image, ships it to two EC2 instances behind an Application Load Balancer,
verifies the deployment, and rolls back automatically if the new version is
unhealthy.

Built to learn the whole path end to end, not to demo one tool.

```
GitHub ──webhook──> Jenkins ──build──> Docker Hub
                       │
                       └──SSH──> EC2 (x2) ──> Amazon RDS (MySQL)
                                    │              Amazon S3
                                    └── Application Load Balancer
```

---

## What it does

| Capability | How |
|---|---|
| Automated testing on every push | `pytest` runs in a clean container before anything is built |
| Reproducible builds | Multi-stage-aware Dockerfile, non-root user, pinned base image |
| Immutable, versioned artifacts | Every build tagged `v1.0.<build-number>` and pushed to a registry |
| Zero-downtime-oriented deploys | New container starts, is health-checked, then the old one is removed |
| Automatic rollback | If the health check fails, the previous container is restored |
| High availability | Two instances behind an ALB with `/health` checks across two AZs |
| Managed persistence | Amazon RDS for MySQL, private subnet, no public access |
| Keyless cloud access | S3 reached through an EC2 IAM role — no credentials in the image |

---

## Stack

**CI/CD** Jenkins (declarative pipeline as code), GitHub webhooks
**Containers** Docker, Docker Compose, Docker Hub
**AWS** EC2, RDS for MySQL, S3, Application Load Balancer, IAM, Security Groups
**Application** Python 3.12, Flask, Gunicorn, PyMySQL, boto3
**Testing** pytest

---

## Pipeline stages

| # | Stage | Fails the build when |
|---|---|---|
| 1 | Checkout | The repository is unreachable |
| 2 | Test | Any unit test fails — nothing is built |
| 3 | Build image | The Dockerfile errors |
| 4 | Push to registry | Registry authentication fails |
| 5 | Deploy over SSH | The container will not start or is unhealthy (auto-rollback) |
| 6 | Verify | `/health` does not return 200 |

---

## The application

A deliberately small Flask app whose purpose is to make the infrastructure
visible:

- The page shows the **EC2 instance ID that served the request** — refresh it
  behind the load balancer and the value changes
- A form writes rows to **Amazon RDS** and reads them back
- A file upload sends objects to **Amazon S3** using the instance IAM role
- `/health` returns 200 for the ALB health check, and stays 200 under partial
  degradation so a transient database blip does not remove a healthy server from
  rotation

---

## Repository layout

```
├── app/                  Flask application, templates, tests
├── docs/
│   ├── 00-START-HERE.md      Full zero-to-production runbook
│   ├── 01-how-it-works.md    Every concept explained from scratch
│   ├── 02-command-cheatsheet.md
│   └── 03-troubleshooting.md
├── scripts/
│   ├── ec2-setup.sh          Provision the application server
│   ├── jenkins-install.sh    Provision the Jenkins server
│   ├── deploy.sh             Deploy with health check and rollback
│   └── backup-to-s3.sh       Nightly database backup to S3
├── Dockerfile            Annotated line by line
├── Jenkinsfile           Six-stage declarative pipeline
├── docker-compose.yml    Local environment with a throwaway MySQL
└── .env.example          Configuration template (real .env is never committed)
```

---

## Run it locally

```bash
git clone https://github.com/ijlalpk/devops-cicd-aws.git
cd devops-cicd-aws
docker compose up --build
# http://localhost:8080
```

Full deployment instructions: **[docs/00-START-HERE.md](docs/00-START-HERE.md)**

---

## Security decisions

- The database has **no public access** — it accepts connections only from the
  application security group
- The container holds **no AWS credentials**; permissions come from an IAM role
  scoped to a single bucket
- Application secrets live in a `.env` file on the server, `chmod 600`, excluded
  from version control
- Registry and SSH credentials are stored in the Jenkins credential store and
  masked in build logs
- Containers run as a **non-root** user
- The application servers are not directly addressable from the internet; all
  traffic arrives through the load balancer

---

## What I would add next

- Terraform for the infrastructure, so the AWS side is version-controlled too
- HTTPS on the ALB with an ACM certificate
- Amazon ECR instead of Docker Hub, with image vulnerability scanning
- Blue/green deployment via a second target group
- CloudWatch alarms on 5xx rate and target health
- Migration to ECS or EKS once the container count grows

---

**Muhammad Ijlal Mazhar** — [LinkedIn](https://linkedin.com/in/) · [GitHub](https://github.com/ijlalpk)
