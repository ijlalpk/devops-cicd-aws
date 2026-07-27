# DevOps CI/CD Pipeline - Setup Guide 
 
## Prerequisites
- Jenkins server
- GitHub personal access token
- AWS account with EC2, RDS, S3, ALB
- Docker Hub account
- SSH access to EC2 instances

## Quick Start - Local Testing

```bash
# Clone the repository
git clone https://github.com/[YOUR-USERNAME]/devops-cicd-aws.git
cd devops-cicd-aws

# Start everything locally with Docker Compose
docker compose up --build

# Visit the app
# http://localhost:8080

# Watch logs
docker compose logs -f app

# Stop everything
docker compose down -v
```

## Production Deployment Steps

### 1. Set Up Jenkins
- Install Jenkins on a server (EC2 or on-premises)
- Install Docker plugin
- Configure GitHub webhook

### 2. Create AWS Infrastructure
- 2 EC2 instances (Ubuntu 22.04, t3.micro or t3.small)
- 1 RDS MySQL 8.0 instance (private subnet)
- 1 S3 bucket for uploads
- 1 Application Load Balancer
- Security groups (see Jenkinsfile for port requirements)

### 3. Configure Environment Variables on EC2
Create `.env` file on each EC2 instance:


### 4. Run the Pipeline
- Push to main branch
- Jenkins automatically tests, builds, deploys, and verifies

### 5. Troubleshooting
See [03-troubleshooting.md](03-troubleshooting.md) for common issues.
