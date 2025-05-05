#!/bin/bash

# Script to start Jenkins, wait for it to be fully ready, create seed job,
# explicitly stop the initial process, start the final process, and trigger seed job.

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

# Path to the plugins file
PLUGINS_FILE="/usr/share/jenkins/ref/plugins.txt"

# Log file to monitor Jenkins startup
JENKINS_LOG="${JENKINS_HOME}/jenkins.log"

# Function to wait for Jenkins to be ready (checking CLI jar endpoint)
wait_for_jenkins_ready() { # Renamed function for clarity
    local url="$1"
    local timeout=300 # 5 minutes timeout
    local start_time=$(date +%s)

    echo "Waiting for Jenkins to be ready at ${url}..."

    while [ $(($(date +%s) - start_time)) -lt ${timeout} ]; do
        # Use curl to check if the CLI jar endpoint is reachable and returns 200 OK
        # -s: silent, -o /dev/null: discard output, -w "%{http_code}": print http code
        if curl -s -o /dev/null -w "%{http_code}" "${url}/jnlpJars/jenkins-cli.jar" | grep -q "200"; then
            echo "Jenkins is ready."
            return 0 # Success
        fi
        sleep 5 # Check every 5 seconds
    done

    echo "Timeout waiting for Jenkins to be ready."
    return 1 # Failure
}


# Check if the initial setup marker exists
if [ ! -f "${JENKINS_HOME}/.jenkins_setup_complete" ]; then
    echo "--- Jenkins Startup Script ---"
    echo "Initial setup marker not found. Running initial setup..."

    # --- Start Jenkins in background for initial setup ---
    echo "--- Starting Jenkins in background for initial setup ---"
    # Start Jenkins in the background for initial setup tasks
    # Use nohup to ensure it keeps running
    nohup java -Djenkins.install.runSetupWizard=false -jar ${JENKINS_WAR} > ${JENKINS_LOG} 2>&1 &
    JENKINS_PID=$!
    echo "Jenkins started in the background with PID ${JENKINS_PID}. Logs are in ${JENKINS_LOG}."

    # --- Waiting for Jenkins to be fully up and running (first startup) ---
    # Use the simpler readiness check
    wait_for_jenkins_ready ${JENKINS_URL} # <-- Updated function call
    if [ $? -ne 0 ]; then
        echo "Initial Jenkins process did not become ready. Exiting."
        exit 1
    fi

    echo "Jenkins is ready for initial setup tasks."

    # --- Install plugins from plugins.txt using Jenkins CLI ---
    echo "--- Installing plugins from ${PLUGINS_FILE} using Jenkins CLI ---"
    if [ -f "${PLUGINS_FILE}" ]; then
        # Read plugins from the file, one per line, and pass them to the CLI install-plugin command
        # Use xargs to handle potential whitespace issues and pass multiple plugins efficiently
        readarray -t PLUGINS < "${PLUGINS_FILE}"
        if [ ${#PLUGINS[@]} -gt 0 ]; then
             # Download jenkins-cli.jar if not already present before using it
             if [ ! -f "${CLI_JAR}" ] || ! head -n 1 "${CLI_JAR}" | grep -q "PK"; then
                 echo "Downloading jenkins-cli.jar for plugin installation..."
                 curl -s -o "${CLI_JAR}" "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"
                 if [ ! -f "${CLI_JAR}" ] || ! head -n 1 "${CLI_JAR}" | grep -q "PK"; then
                      echo "Error: jenkins-cli.jar not downloaded for plugin installation."
                      echo "Warning: Could not download jenkins-cli.jar to install plugins."
                 fi
             fi

             # Only attempt plugin installation if CLI jar was downloaded
             if [ -f "${CLI_JAR}" ]; then
                 # Filter out comments and empty lines before piping to xargs
                 printf "%s\n" "${PLUGINS[@]}" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | xargs java -jar "${CLI_JAR}" -s "${JENKINS_URL}" install-plugin
                 if [ $? -ne 0 ]; then
                     echo "Error during plugin installation using Jenkins CLI. Check the output above for details."
                     echo "Warning: Plugin installation failed, but continuing startup."
                 else
                     echo "Plugin installation completed using Jenkins CLI."
                 fi
             fi
        else
            echo "${PLUGINS_FILE} is empty. No plugins to install."
        fi
    else
        echo "Warning: ${PLUGINS_FILE} not found. Skipping plugin installation using Jenkins CLI."
    fi
    # --- End plugin installation using CLI ---

    echo "--- Running job creation script ---"
    # Run the script to create the seed job
    # Ensure CLI_JAR and JENKINS_URL are passed as arguments if needed by create-seed-job.sh
    # Download jenkins-cli.jar again here if create-seed-job.sh needs it and might run independently
    if [ ! -f "${CLI_JAR}" ] || ! head -n 1 "${CLI_JAR}" | grep -q "PK"; then
        echo "Downloading jenkins-cli.jar for job creation script..."
        curl -s -o "${CLI_JAR}" "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"
        if [ ! -f "${CLI_JAR}" ] || ! head -n 1 "${CLI_JAR}" | grep -q "PK"; then
            echo "Error: jenkins-cli.jar not downloaded for job creation."
            exit 1 # This is likely a fatal error for job creation
        fi
    fi

    ${CREATE_SCRIPT} ${JENKINS_URL} ${CLI_JAR} ${SEED_CONFIG}
    if [ $? -ne 0 ]; then
        echo "Job creation script failed. Check its output for details."
        exit 1
    fi
    echo "Job creation script completed successfully."


    echo "--- Stopping initial Jenkins process (PID ${JENKINS_PID}) ---"
    # Explicitly kill the initial background process
    kill ${JENKINS_PID}
    echo "Sent kill signal to PID ${JENKINS_PID}."

    # --- Wait for port 8080 to be free ---
    echo "Waiting for port 8080 to be free after initial process stop..."
    port_wait_timeout=120 # Wait up to 2 minutes for the port to be free
    port_start_time=$(date +%s)
    port_free=false

    while [ $(($(date +%s) - port_start_time)) -lt ${port_wait_timeout} ]; do
        # Check if port 8080 is NOT listening
        if ! nc -z localhost 8080 > /dev/null 2>&1; then
            echo "Port 8080 is free."
            port_free=true
            break
        fi
        sleep 2 # Check every 2 seconds
    done

    if [ "$port_free" = false ]; then
        echo "Timeout waiting for port 8080 to be free."
        echo "Another process might be holding onto the port. Check container or host networking."
        exit 1 # Exit with an error if the port doesn't become free
    fi
    echo "Port 8080 is confirmed free."
    # --- End wait for port free ---


    # Create the marker file to indicate initial setup is complete
    touch "${JENKINS_HOME}/.jenkins_setup_complete"

    echo "--- Initial setup complete. Starting final Jenkins process ---"
    # Start the final Jenkins process in the foreground
    # Use exec to replace the current script process with the java process
    # This will only happen after the initial setup is complete and successful
    exec java -Djenkins.install.runSetupWizard=false -jar ${JENKINS_WAR}

else
    echo "--- Jenkins Startup Script ---"
    echo "Initial setup marker found. Skipping initial setup."
    echo "--- Starting Jenkins ---"
    # If marker exists, just start Jenkins normally
    # The exec command below will replace the current script process
    # We don't need to manually wait or trigger jobs here as the initial setup handled that
    # If you need actions on *every* startup, they should be placed after the initial setup block
    exec java -Djenkins.install.runSetupWizard=false -jar ${JENKINS_WAR}

fi
