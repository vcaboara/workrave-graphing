#!/bin/bash

# Script to start Jenkins, wait for it to be ready, and create a seed job

# Set the Jenkins home directory
JENKINS_HOME="/var/jenkins_home"
# Set the Jenkins URL (within the container)
JENKINS_URL="http://localhost:8080"
# Path to the Jenkins WAR file
JENKINS_WAR="/usr/share/jenkins/jenkins.war"
# Path for the CLI jar
CLI_JAR="/tmp/jenkins-cli.jar"
# Path to the seed job config XML
SEED_CONFIG="/usr/local/bin/seed-job-config.xml"
# Path to the job creation script
CREATE_SCRIPT="/usr/local/bin/create-seed-job.sh"

# Check if the initial setup marker exists (created after first successful startup)
# This prevents running the initial setup on subsequent container restarts with a persistent volume
if [ ! -f "${JENKINS_HOME}/.jenkins_setup_complete" ]; then
    echo "--- Jenkins Startup Script ---"
    echo "Initial setup marker not found. Running initial setup..."

    echo "--- Starting Jenkins in background for initial setup ---"
    # Start Jenkins in the background
    java -Djenkins.install.runSetupWizard=false -jar ${JENKINS_WAR} &
    JENKINS_PID=$!
    echo "Jenkins started in the background with PID ${JENKINS_PID}."

    echo "--- Waiting for Jenkins to be fully ready (checking CLI endpoint) ---"
    # Wait for Jenkins to be ready by checking the CLI endpoint
    WAIT_SECONDS=10
    MAX_ATTEMPTS=60 # Wait up to 10 minutes (60 * 10 seconds)
    ATTEMPT=0

    while [ ${ATTEMPT} -lt ${MAX_ATTEMPTS} ]; do
        ATTEMPT=$((ATTEMPT + 1))
        echo "Attempt ${ATTEMPT}: Checking if Jenkins CLI endpoint is available at ${JENKINS_URL}/jnlpJars/jenkins-cli.jar..."
        # Use curl to check the HTTP status code
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${JENKINS_URL}/jnlpJars/jenkins-cli.jar)

        if [ "${HTTP_STATUS}" -eq 200 ]; then
            echo "Jenkins CLI endpoint is available (status 200)."
            break # Exit the loop if successful
        else
            echo "Jenkins CLI endpoint not yet available (status ${HTTP_STATUS}). Waiting ${WAIT_SECONDS}s..."
            sleep ${WAIT_SECONDS}
        fi

        if [ ${ATTEMPT} -eq ${MAX_ATTEMPTS} ]; then
            echo "Maximum attempts reached. Jenkins CLI endpoint did not become available."
            echo "Please check Jenkins logs for errors."
            exit 1 # Exit with an error code if waiting times out
        fi
    done

    echo "Jenkins is ready."

    echo "--- Running job creation script ---"
    # Now that Jenkins is ready, run the script to create the seed job
    # Pass necessary variables to the script
    ${CREATE_SCRIPT} ${JENKINS_URL} ${CLI_JAR} ${SEED_CONFIG}

    # Check if the job creation script was successful
    if [ $? -eq 0 ]; then
        echo "Job creation script completed successfully."
        # Create the marker file to indicate initial setup is complete
        touch "${JENKINS_HOME}/.jenkins_setup_complete"
    else
        echo "Job creation script failed. Check its output for details."
        exit 1 # Exit with an error code if job creation fails
    fi

    # Keep the Jenkins process running in the background
    wait ${JENKINS_PID}

else
    echo "--- Jenkins Startup Script ---"
    echo "Initial setup marker found. Skipping initial setup."
    echo "--- Starting Jenkins ---"
    # If marker exists, just start Jenkins normally
    exec java -Djenkins.install.runSetupWizard=false -jar ${JENKINS_WAR}
fi
