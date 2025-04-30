#!/bin/bash

# Script to download jenkins-cli.jar and create the seed job

# Accept arguments passed from jenkins-startup.sh
JENKINS_URL="$1"
CLI_JAR="$2"
SEED_CONFIG="$3"

# Define the seed job name
SEED_JOB_NAME="job-dsl-seed"

echo "Waiting for Jenkins at ${JENKINS_URL}..."
# The jenkins-startup.sh script already waited for the CLI endpoint,
# but a small additional sleep here might not hurt before downloading.
sleep 5 # Optional small delay

echo "Downloading jenkins-cli.jar..."
# Download the CLI jar
curl -s -o ${CLI_JAR} ${JENKINS_URL}/jnlpJars/jenkins-cli.jar

# Check if the download was successful and the file is a valid jar
if [ ! -f "${CLI_JAR}" ] || ! head -n 1 "${CLI_JAR}" | grep -q "PK"; then
    echo "Error: jenkins-cli.jar not downloaded or is not a valid JAR file."
    # Optionally print the content of the downloaded file for debugging
    # cat ${CLI_JAR}
    exit 1
fi

echo "jenkins-cli.jar downloaded to ${CLI_JAR}."

echo "Checking if seed job ${SEED_JOB_NAME} already exists..."
# Check if the seed job already exists using the CLI
# We expect a non-zero exit code if the job does NOT exist
java -jar ${CLI_JAR} -s ${JENKINS_URL} get-job ${SEED_JOB_NAME} > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Seed job ${SEED_JOB_NAME} already exists. Skipping creation."
else
    echo "Seed job ${SEED_JOB_NAME} does not exist. Creating job..."
    # Create the seed job using the CLI and the seed job config XML
    java -jar ${CLI_JAR} -s ${JENKINS_URL} create-job ${SEED_JOB_NAME} < ${SEED_CONFIG}

    # Check if the job creation command was successful
    if [ $? -eq 0 ]; then
        echo "Seed job ${SEED_JOB_NAME} created successfully."
    else
        echo "Error: Failed to create seed job ${SEED_JOB_NAME}."
        exit 1
    fi
fi

# You might want to trigger the seed job automatically after creation
# echo "Triggering seed job ${SEED_JOB_NAME}..."
# java -jar ${CLI_JAR} -s ${JENKINS_URL} build ${SEED_JOB_NAME}

exit 0 # Exit successfully
