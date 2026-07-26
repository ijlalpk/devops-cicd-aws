# =============================================================================
# Dockerfile - the recipe that turns your code into a portable image.
#
# Read it top to bottom. Every line is one instruction. Docker runs them in
# order and saves the result of each one as a cached "layer". That caching is
# why the ORDER of these lines matters so much for build speed.
# =============================================================================

# 1. The base. "slim" = Debian with Python, minus the extras. Small = fast to
#    push, fast to pull, fewer packages that can have security holes.
#    Always pin a version. "python:latest" changes under you and breaks builds.
FROM python:3.12-slim

# 2. Metadata. Optional, but real teams do it.
LABEL maintainer="Muhammad Ijlal Mazhar" \
      description="DevOps CI/CD demo - Flask on EC2 with RDS and S3"

# 3. Environment settings for Python inside containers.
#    PYTHONDONTWRITEBYTECODE - skip .pyc files, nothing here will reuse them.
#    PYTHONUNBUFFERED        - print logs immediately so 'docker logs' is live.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 4. Every command after this runs inside /app.
WORKDIR /app

# 5. Copy ONLY the requirements file first, then install.
#    Why not copy everything at once? Because Docker caches layers. As long as
#    requirements.txt has not changed, Docker reuses the installed packages and
#    skips this slow step. Change one line of app.py and the build is instant.
#    Copy everything first and you reinstall all packages on every single build.
COPY app/requirements.txt .

# 6. --no-cache-dir keeps pip's download cache out of the image (smaller image).
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 7. Now the application code - the part that changes on every commit.
COPY app/ .

# 8. Run as a non-root user. If somebody breaks into the container, they land
#    as "appuser" with almost no power instead of as root. Security basics.
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

# 9. Documentation for humans: this app talks on port 5000.
#    EXPOSE does not publish the port. Publishing happens with 'docker run -p'.
EXPOSE 5000

# 10. Docker's own health check. 'docker ps' will show healthy / unhealthy.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import requests,sys; sys.exit(0 if requests.get('http://localhost:5000/health',timeout=3).ok else 1)"

# 11. The command that runs when the container starts.
#     Gunicorn, not 'flask run'. Flask's dev server is single-threaded and
#     explicitly not for production. Gunicorn runs multiple workers.
#     --access-logfile - sends request logs to stdout so 'docker logs' sees them.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", \
     "--workers", "3", \
     "--timeout", "60", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "app:app"]
