# How the Pipeline Works.  

## The Flow

## Pipeline Stages Explained

### Stage 1: Checkout
- Clone the repository from GitHub
- Fails if repo is unreachable

### Stage 2: Test
- Run pytest inside a container
- Tests the Python code before building anything
- Fails if any test fails

### Stage 3: Build Image
- Run `docker build` with the Dockerfile
- Multi-stage: compile stage, then minimal runtime stage
- Tag the image with build number: `v1.0.123`

### Stage 4: Push Registry
- Push image to Docker Hub
- Requires Docker Hub credentials stored in Jenkins
- Credentials masked in logs

### Stage 5: Deploy
- SSH to EC2 instance 1
- Pull the new image
- Run health check
- If healthy: remove old container
- If unhealthy: stay on old image (rollback)
- Repeat for instance 2

### Stage 6: Verify
- Call `/health` endpoint on ALB
- ALB has 2 targets (EC2-1, EC2-2)
- Returns 200 if at least one is healthy

## Application Routes

| URL | Purpose |
|---|---|
| `/` | Main page - shows instance ID, RDS status, S3 status |
| `/feedback` | POST form to save feedback to RDS |
| `/upload` | POST form to upload file to S3 |
| `/health` | GET health check for ALB (always 200) |
| `/api/info` | GET JSON with system info |

## Why This Matters

- **Automated**: No manual clicking
- **Fast**: Entire pipeline runs in ~5 minutes
- **Safe**: Tests run before deployment
- **Resilient**: Auto-rollback if new version fails
- **Visible**: You see which EC2 served your request
- **Learnable**: Every AWS service is visible in the app
