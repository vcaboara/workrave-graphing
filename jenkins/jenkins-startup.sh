#!/bin/bash
# Script: jenkins-startup.sh
# Description: Wrapper script to start Jenkins, run initial setup (job creation, restart),
#              and then just keep Jenkins running on subsequent starts.

# Exit immediately if a command exits with a non-zero status.
# We will temporarily disable this around the CLI safe-restart command.
set -e

JENKINS_URL="http://localhost:8080"
JENKINS_CLI="/tmp/jenkins-cli.jar"
SETUP_MARKER="/var/jenkins_home/.setup_complete" # Marker file for initial setup completion

echo "--- Jenkins Startup Script ---"

# Check if the initial setup has already run
if [ -f "${SETUP_MARKER}" ]; then
  echo "Initial setup marker found (${SETUP_MARKER}). Skipping job creation and restart."
  echo "--- Starting main Jenkins process in foreground ---"
  # If setup is complete, just start the main Jenkins process in the foreground
  # This ensures the container stays alive and Jenkins runs normally.
  exec /usr/local/bin/jenkins.sh
else
  echo "Initial setup marker not found. Running initial setup..."

  # --- Start the main Jenkins process ---
  echo "--- Starting Jenkins in background for initial setup ---"
  # Execute the original Jenkins entrypoint script in the background
  /usr/local/bin/jenkins.sh &

  # Store the PID of the background Jenkins process
  JENKINS_PID=$!

  echo "Jenkins started in the background with PID ${JENKINS_PID}."

  # --- Wait for Jenkins to be ready ---
  echo "--- Waiting for Jenkins to be ready ---"
  MAX_WAIT_TIME=180 # Maximum time to wait in seconds
  WAIT_INTERVAL=5   # Time to wait between checks in seconds
  ELAPSED_TIME=0

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
    # Kill the background Jenkins process before exiting
    kill ${JENKINS_PID} || true
    exit 1
  fi

  echo "Jenkins is ready."

  # --- Run the job creation script ---
  echo "--- Running job creation script ---"
  # Assuming create-seed-job.sh is copied to /usr/local/bin/ in the Dockerfile
  if [ -f /usr/local/bin/create-seed-job.sh ]; then
    # Pass the Jenkins URL to the job creation script
    /usr/local/bin/create-seed-job.sh "${JENKINS_URL}"
    echo "Job creation script finished."
  else
    echo "Warning: Job creation script /usr/local/bin/create-seed-job.sh not found in the container."
  fi

  # --- Trigger a safe restart to activate installed plugins and config ---
  # This is necessary because plugins installed via plugins.txt and some
  # configuration changes (like job creation) often require a restart.
  echo "--- Triggering safe restart to activate plugins and config ---"
  # Wait a bit to ensure Jenkins is stable after job creation
  sleep 10
  # Use the downloaded CLI to trigger a safe restart
  # Assumes the CLI is available at /tmp/jenkins-cli.jar (downloaded by create-seed-job.sh)
  if [ -f "${JENKINS_CLI}" ]; then
    echo "Executing safe-restart via Jenkins CLI..."
    # Temporarily disable set -e as safe-restart command might exit with non-zero in some cases
    set +e
    # Note: Depending on your Jenkins security setup, you might need to authenticate the CLI command
    # using --username and --password or an API token. The init script setup might allow anonymous
    # CLI access initially, but this is not guaranteed or recommended for production.
    java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" safe-restart
    CLI_EXIT_CODE=$?
    # Re-enable set -e
    set -e
    if [ ${CLI_EXIT_CODE} -eq 0 ]; then
      echo "Safe restart command sent successfully."
    else
      echo "Warning: Safe restart command via CLI exited with code ${CLI_EXIT_CODE}. It might still work."
    fi
  else
    echo "Warning: Jenkins CLI not found at ${JENKINS_CLI}. Cannot trigger safe restart."
  fi

  # --- Create the setup completion marker file ---
  # This indicates that the initial setup steps have been performed.
  echo "Creating setup completion marker file: ${SETUP_MARKER}"
  touch "${SETUP_MARKER}"
  echo "Setup completion marker created."

  # --- Wait for the original Jenkins process to exit after the restart command ---
  # The safe-restart command will cause the original Jenkins process (started in the background)
  # to shut down. This script (the ENTRYPOINT) will then wait for that background process to exit.
  # Once it exits, Docker will start a new container process, which will again run this script.
  # The next time this script runs, it will find the SETUP_MARKER and start Jenkins in the foreground.
  echo "--- Waiting for the original Jenkins process (PID ${JENKINS_PID}) to exit ---"
  wait ${JENKINS_PID}
  echo "Original Jenkins process exited."

  # The container will now exit, and Docker Compose will restart it,
  # which will then hit the 'if [ -f "${SETUP_MARKER}" ]' condition
  # and start Jenkins in the foreground for normal operation.
fi

echo "--- Jenkins Startup Script Finished ---"
