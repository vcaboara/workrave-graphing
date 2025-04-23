#!/bin/bash
# Script: create-seed-job.sh
# Description: Downloads jenkins-cli.jar and creates a seed job using Job DSL.

# Exit immediately if a command exits with a non-zero status.
set -e

JENKINS_URL="${1:-http://localhost:8080}" # Get Jenkins URL from argument or use default
JENKINS_CLI="/tmp/jenkins-cli.jar"      # Download CLI to /tmp
SEED_JOB_NAME="job-dsl-seed"
SEED_JOB_CONFIG="/usr/local/bin/seed-job-config.xml" # Path where config file is copied

echo "Waiting for Jenkins at ${JENKINS_URL}..."

# Wait for Jenkins to be accessible
# Use a simple loop with curl to check if the URL is reachable
wait_for_jenkins() {
  local url="$1"
  local max_attempts=30
  local attempt=0
  local wait_interval=5

  while [ $attempt -lt $max_attempts ]; do
    if curl -s -I "$url" > /dev/null; then
      return 0 # Success
    fi
    echo "Attempt $((attempt + 1)): Jenkins not ready. Waiting ${wait_interval}s..."
    sleep "$wait_interval"
    attempt=$((attempt + 1))
  done
  return 1 # Timeout
}

if ! wait_for_jenkins "${JENKINS_URL}/login"; then
  echo "Error: Timed out waiting for Jenkins to become ready."
  exit 1
fi

echo "Jenkins is ready."

echo "Downloading jenkins-cli.jar..."
# Download jenkins-cli.jar to /tmp/
wget "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "${JENKINS_CLI}"
echo "Done"

# Check if the config file exists
if [ ! -f "${SEED_JOB_CONFIG}" ]; then
  echo "Error: Seed job config file not found: ${SEED_JOB_CONFIG}"
  exit 1
fi

echo "Creating seed job ${SEED_JOB_NAME}..."
# Use the downloaded CLI to create the job
# Assuming you have configured security to allow this or are running in a fresh instance
# where anonymous creation is temporarily allowed.
# For production, you would need to authenticate the CLI command.
java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" create-job "${SEED_JOB_NAME}" < "${SEED_JOB_CONFIG}"

if [ $? -eq 0 ]; then
  echo "Seed job ${SEED_JOB_NAME} created successfully."
else
  echo "Error creating seed job ${SEED_JOB_NAME}."
  # Consider adding more detailed error handling based on CLI output
  exit 1
fi

# Clean up the downloaded jenkins-cli.jar
rm "${JENKINS_CLI}"
