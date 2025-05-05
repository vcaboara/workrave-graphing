#!/bin/bash

# Script to download jenkins-cli.jar and create the seed job (without triggering)

# Accept arguments passed from jenkins-startup.sh
JENKINS_URL="$1"
CLI_JAR="$2"
SEED_CONFIG="$3"

# Define the seed job name
SEED_JOB_NAME="job-dsl-seed"

echo "Waiting for Jenkins at ${JENKINS_URL}..."
# A small delay here might not hurt, though jenkins-startup.sh waits for Jenkins to be fully up.
sleep 5 # Optional small delay

# Check if jenkins-cli.jar already exists and is valid, otherwise download it
if [ ! -f "${CLI_JAR}" ] || ! head -n 1 "${CLI_JAR}" | grep -q "PK"; then
    echo "Downloading jenkins-cli.jar..."
    curl -s -o ${CLI_JAR} ${JENKINS_URL}/jnlpJars/jenkins-cli.jar

    # Final check after download
    if [ ! -f "${CLI_JAR}" ] || ! head -n 1 "${CLI_JAR}" | grep -q "PK"; then
        echo "Error: jenkins-cli.jar not downloaded or is not a valid JAR file after attempt."
        # Optionally print the content of the downloaded file for debugging
        # cat ${CLI_JAR}
        exit 1
    fi
    echo "jenkins-cli.jar downloaded to ${CLI_JAR}."
else
    echo "jenkins-cli.jar already exists and is valid at ${CLI_JAR}."
fi


echo "Checking if seed job ${SEED_JOB_NAME} already exists..."
# Check if the seed job already exists using the CLI
# We expect a non-zero exit code if the job does NOT exist
java -jar ${CLI_JAR} -s ${JENKINS_URL} get-job ${SEED_JOB_NAME} > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Seed job ${SEED_JOB_NAME} already exists. Skipping creation."
    # We no longer trigger the job here.
else
    echo "Seed job ${SEED_JOB_NAME} does not exist. Creating job..."
    # Create the seed job using the CLI and the seed job config XML
    java -jar ${CLI_JAR} -s ${JENKINS_URL} create-job ${SEED_JOB_NAME} < ${SEED_CONFIG}

    # Check if the job creation command was successful
    if [ $? -eq 0 ]; then
        echo "Seed job ${SEED_JOB_NAME} created successfully."
        # We no longer trigger the job here.
    else
        echo "Error: Failed to create seed job ${SEED_JOB_NAME}."
        exit 1
    fi
fi

# This script now exits successfully after creating the job (if needed),
# leaving the triggering to the startup script after a restart.
exit 0
