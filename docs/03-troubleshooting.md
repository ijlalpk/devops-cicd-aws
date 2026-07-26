# Troubleshooting Guide

## Pipeline Fails at Stage: Test

**Error:** `pytest: command not found`

**Solution:**
- Check `requirements.txt` has `pytest==8.2.2`
- Dockerfile must run `pip install -r requirements.txt` before tests

---

## Pipeline Fails at Stage: Build Image

**Error:** `failed to export image: image build must define at least one tag`

**Solution:**
- Check Jenkinsfile has `docker build -t ijlalpk/devops-app:v1.0.${BUILD_NUMBER} .`
- Image must have a tag (name:version)

---

## Pipeline Fails at Stage: Push Registry

**Error:** `denied: requested access to the resource is denied`

**Solution:**
- Your Docker Hub credentials in Jenkins are wrong
- Re-add credentials: Jenkins → Manage Jenkins → Credentials → Add
- Use personal access token, not password
- Re-run pipeline

---

## Pipeline Fails at Stage: Deploy

**Error:** `Host key verification failed`

**Solution:**
- SSH key permissions wrong: `chmod 600 my-key.pem`
- SSH key not available on Jenkins server
- EC2 security group doesn't allow SSH (port 22)
- Check: `ssh -i my-key.pem ec2-user@instance-ip` works manually first

---

## Docker Container Won't Start

**Error:** `docker: Error response from daemon: bind: address already in use`

**Solution:**
```bash
# Find what's using port 8080
lsof -i :8080

# Kill it
kill -9 <PID>

# Or use different port
docker run -p 9000:5000 ...
```

---

## App Runs But Can't Reach Database

**Error:** `pymysql.err.OperationalError: (2003, "Can't connect to MySQL server"`

**Solution:**
- Check RDS is in same VPC as EC2
- Check security group allows port 3306 from EC2 security group
- Check RDS endpoint is correct in .env
- Test manually: `mysql -h rds-endpoint -u appuser -p`

---

## App Runs But Can't Upload to S3

**Error:** `botocore.exceptions.ClientError: An error occurred (AccessDenied)`

**Solution:**
- EC2 instance doesn't have IAM role
- IAM role doesn't have S3 bucket permission
- S3_BUCKET env variable is empty or wrong
- Check: `aws s3 ls s3://bucket-name/` works from EC2

---

## ALB Health Check Failing

**Error:** Target shows "Unhealthy" in ALB Target Groups

**Solution:**
- Container is not running: `docker ps` on EC2
- Container is running but `/health` returns non-200
- Health check port (5000) not exposed in security group
- ALB can't reach target on port 5000
- Check: `curl http://localhost:5000/health` returns 200

---

## Local Docker Compose Won't Start

**Error:** `docker compose up` fails

**Solution:**
```bash
# Check syntax
docker compose config

# Check Docker is running
docker ps

# Check images exist
docker images

# Rebuild everything
docker compose down -v
docker compose build --no-cache
docker compose up
```

---

## How to Debug Live

1. **SSH to EC2:**
```bash
   ssh -i key.pem ec2-user@instance-ip
```

2. **Check container:**
```bash
   docker ps
   docker logs -f container-id
```

3. **Check database connection:**
```bash
   mysql -h rds-endpoint -u appuser -p
   SHOW TABLES;
```

4. **Check S3 access:**
```bash
   aws s3 ls s3://bucket/
```

5. **Test app endpoint:**
```bash
   curl http://localhost:5000/health
   curl http://alb-dns/health
```
