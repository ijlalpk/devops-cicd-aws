# Command Cheatsheet

## Docker Compose (Local Testing)

```bash
# Start everything
docker compose up --build

# Watch logs from app container
docker compose logs -f app

# Watch logs from database container
docker compose logs -f db

# Run a command inside the app container
docker compose exec app bash

# Stop everything (keeps volumes)
docker compose down

# Stop and delete all data
docker compose down -v

# Restart just the app
docker compose restart app
```

## Docker (Manual Commands)

```bash
# Build image locally
docker build -t devops-app:latest .

# Run container locally
docker run -p 8080:5000 \
  -e DB_HOST=localhost \
  -e DB_USER=appuser \
  -e DB_PASSWORD=test \
  devops-app:latest

# Login to Docker Hub
docker login

# Push image to Docker Hub
docker tag devops-app:latest ijlalpk/devops-app:v1.0.1
docker push ijlalpk/devops-app:v1.0.1
```

## SSH to EC2 (Deployment)

```bash
# Connect to instance
ssh -i my-key.pem ec2-user@ec2-instance-ip

# Check running containers
docker ps

# View container logs
docker logs -f app-container-name

# Pull latest image and restart
docker pull ijlalpk/devops-app:latest
docker stop app-container
docker run -d \
  --name app-container \
  -p 80:5000 \
  -e DB_HOST=rds-endpoint \
  ijlalpk/devops-app:latest
```

## Jenkins (Pipeline)

```bash
# Trigger pipeline manually
# (From Jenkins UI: click "Build Now")

# View build logs
# (From Jenkins UI: click build number → Console Output)

# Restart Jenkins
sudo systemctl restart jenkins
```

## AWS CLI (Optional)

```bash
# Configure AWS credentials
aws configure

# Check S3 bucket
aws s3 ls s3://my-bucket/

# Check RDS status
aws rds describe-db-instances --db-instance-identifier my-db

# Check EC2 instances
aws ec2 describe-instances --region eu-north-1
```

## Troubleshooting Commands

```bash
# Check if Docker daemon is running
docker ps

# Check if Jenkins is running
sudo systemctl status jenkins

# Check if MySQL is accessible
mysql -h rds-endpoint -u appuser -p

# Test S3 access from EC2
aws s3 ls s3://my-bucket/ --region eu-north-1
```
