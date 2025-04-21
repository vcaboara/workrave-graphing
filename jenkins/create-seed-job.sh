#!/bin/bash

JENKINS_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="your_very_secure_docker_password" # **Get this securely**
SEED_JOB_NAME="job-dsl-seed"
SEED_JOB_CONFIG_XML_FILE="seed-job-config.xml" # File containing the job XML

# Wait for Jenkins to be ready (implement a robust wait here)
echo "Waiting for Jenkins at $JENKINS_URL..."
while ! curl -s "$JENKINS_URL/login" > /dev/null; do
  sleep 5
done
echo "Jenkins is ready."

# Download jenkins-cli.jar if not present
if [ ! -f jenkins-cli.jar ]; then
  echo "Downloading jenkins-cli.jar..."
  wget "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
fi

# Create the job using the CLI
echo "Creating seed job $SEED_JOB_NAME..."
java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$ADMIN_USER:$ADMIN_PASSWORD" create-job "$SEED_JOB_NAME" < "$SEED_JOB_CONFIG_XML_FILE"

if [ $? -eq 0 ]; then
  echo "Seed job $SEED_JOB_NAME created successfully."
  # Optional: Trigger the seed job build
  # java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$ADMIN_USER:$ADMIN_PASSWORD" build "$SEED_JOB_NAME"
else
  echo "Error creating seed job $SEED_JOB_NAME."
fi
