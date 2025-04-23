#!/bin/bash
# Script: create-seed-job.sh
# Description: Downloads jenkins-cli.jar and creates or updates a seed job using Job DSL.

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
    # Use curl to check if the /login page is accessible (requires Jenkins to be up)
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

# Download jenkins-cli.jar if it doesn't exist
if [ ! -f "${JENKINS_CLI}" ]; then
  echo "Downloading jenkins-cli.jar..."
  wget "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "${JENKINS_CLI}"
  echo "Done"
else
  echo "jenkins-cli.jar already exists at ${JENKINS_CLI}."
fi


# Check if the config file exists
if [ ! -f "${SEED_JOB_CONFIG}" ]; then
  echo "Error: Seed job config file not found: ${SEED_JOB_CONFIG}"
  exit 1
fi

echo "Checking if seed job ${SEED_JOB_NAME} already exists..."

# Temporarily disable set -e to capture the exit code of get-job
set +e
# Check if the job exists using the Jenkins CLI get-job command
# Redirect stderr to /dev/null to suppress "No such job" errors
java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" get-job "${SEED_JOB_NAME}" > /dev/null 2>&1
JOB_EXISTS=$? # Capture the exit code of the get-job command
# Re-enable set -e
set -e

if [ ${JOB_EXISTS} -eq 0 ]; then
  echo "Seed job ${SEED_JOB_NAME} already exists. Updating job..."
  # Use update-job if the job exists
  java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" update-job "${SEED_JOB_NAME}" < "${SEED_JOB_CONFIG}"
  CLI_EXIT_CODE=$?
  if [ ${CLI_EXIT_CODE} -eq 0 ]; then
    echo "Seed job ${SEED_JOB_NAME} updated successfully."
  else
    echo "Error updating seed job ${SEED_JOB_NAME}. CLI exit code: ${CLI_EXIT_CODE}"
    exit 1
  fi
else
  echo "Seed job ${SEED_JOB_NAME} does not exist. Creating job..."
  # Use create-job if the job does not exist
  java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" create-job "${SEED_JOB_NAME}" < "${SEED_JOB_CONFIG}"
  CLI_EXIT_CODE=$?
  if [ ${CLI_EXIT_CODE} -eq 0 ]; then
    echo "Seed job ${SEED_JOB_NAME} created successfully."
  else
    echo "Error creating seed job ${SEED_JOB_NAME}. CLI exit code: ${CLI_EXIT_CODE}"
    exit 1
  fi
fi

# REMOVED: Clean up the downloaded jenkins-cli.jar (kept for potential reuse in jenkins-startup.sh)
# rm "${JENKINS_CLI}"
