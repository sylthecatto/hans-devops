# Base image from Dockerhub, as of writing this, python 3.14 is the stable release, 3.15 is available but it is still a rolling release and could add changes that could break
FROM python:3.14-slim

# Set working directory
WORKDIR /app 

# Copy the requirements file 
COPY exam-source-requirements.txt .

# Install dependencies (Flask & gunicorn)
RUN pip install --no-cache-dir -r exam-source-requirements.txt

# Copy source code
COPY exam-source-app.py .

# Copy default config
COPY exam-source-config.json /app/config/config.json

# Jenkins passes the real version in at build time
ARG APP_VERSION=unset
ENV APP_VERSION=$APP_VERSION

EXPOSE 5000

# Setup an app user so the container doesn't run as the root user
RUN useradd app && chown -R app /app
USER app


# Run
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "exam-source-app:app"]
