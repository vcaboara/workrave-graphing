#!/bin/bash
# Script: jenkins-startup.sh
# Description: Wrapper script to start Jenkins and then run job creation scripts.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Start the main Jenkins process ---
echo "--- Starting Jenkins ---"
# Execute the original Jenkins entrypoint script in the background
# Changed from jenkins-foreground to jenkins.sh
/usr/local/bin/jenkins.sh &

# Store the PID of the background Jenkins process
JENKINS_PID=$!

echo "Jenkins started in the background with PID ${JENKINS_PID}."

# --- Wait for Jenkins to be ready ---
echo "--- Waiting for Jenkins to be ready ---"
JENKINS_URL="http://localhost:8080"
MAX_WAIT_TIME=180 # Maximum time to wait in seconds
WAIT_INTERVAL=5   # Time to wait between checks in seconds
ELAPSED_TIME=0

while [ ${ELAPSED_TIME} -lt ${MAX_WAIT_TIME} ]; do
  echo "Checking if Jenkins is available at ${JENKINS_URL}..."
  # Use curl to check if the /login page is accessible (requires Jenkins to be up)
  if curl -s -I "${JENKINS_URL}/login" > /dev/null; then
    echo "Jenkins is ready."
    break
  fi

  echo "Jenkins not ready yet. Waiting ${WAIT_INTERVAL} seconds..."
  sleep ${WAIT_INTERVAL}
  ELAPSED_TIME=$((ELAPSED_TIME + WAIT_INTERVAL))

  # Optional: Check if the background Jenkins process is still running
  if ! kill -0 ${JENKINS_PID} 2>/dev/null; then
      echo "Error: Jenkins process terminated unexpectedly."
      exit 1 # Exit if Jenkins process died
  fi
done

# Check if we timed out
if [ ${ELAPSED_TIME} -ge ${MAX_WAIT_TIME} ]; then
  echo "Error: Timed out waiting for Jenkins to become ready."
  exit 1
fi

# --- Run the job creation script ---
echo "--- Running job creation script ---"
# Assuming create-seed-job.sh is copied to /usr/local/bin/ in the Dockerfile
if [ -f /usr/local/bin/create-seed-job.sh ]; then
  /usr/local/bin/create-seed-job.sh
  echo "Job creation script finished."
else
  echo "Warning: Job creation script /usr/local/bin/create-seed-job.sh not found in the container."
fi


# --- Keep the container running by waiting for the Jenkins process ---
echo "--- Setup complete. Keeping container alive by waiting for the Jenkins process ---"
wait ${JENKINS_PID}
