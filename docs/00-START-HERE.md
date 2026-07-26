# DevOps CI/CD Pipeline - Setup Guide

## Prerequisites
- Jenkins server with Docker installed
- GitHub personal access token
- AWS account with EC2, RDS, S3, ALB
- Docker Hub account

## Quick Start

### Local Testing
```bash
docker compose up --build
# Visit http://localhost:8080
```

### Production Deployment
1. Configure Jenkins
2. Add GitHub webhook
3. Deploy EC2 instances
4. Configure RDS
5. Set up S3 bucket
6. Configure ALB

See full guide in [01-how-it-works.md](01-how-it-works.md)
