FROM jenkins/jenkins:lts

USER root

# Set debconf frontend to noninteractive to suppress warnings during apt-get install (optional, but good practice)
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary OS packages and the Docker CLI
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
    # Add Docker's official GPG key
    && curl -fsSL https://download.docker.com/linux/debian/gpg | \
        gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    # Set up the stable Docker repository
    && echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    # Update apt-get again after adding the new repository
    && apt-get update \
    # Install the Docker CLI (docker-ce-cli)
    && apt-get install -y --no-install-recommends \
        docker-ce-cli \
        git \
        python3 \
        python3-pip \
        # Add any other packages your plugins or jobs need
    && rm -rf /var/lib/apt/lists/* # Clean up apt cache

# Unset the variable if not needed for subsequent steps (optional)
# ENV DEBIAN_FRONTEND=""

WORKDIR /usr/local/bin
COPY jenkins-startup.sh create-seed-job.sh seed-job-config.xml ./
RUN chmod +x jenkins-startup.sh create-seed-job.sh

USER jenkins

WORKDIR /usr/share/jenkins
# Copy the plugins list file - The official entrypoint uses this for auto-installation
# If your Groovy script needs seed-job-config.xml, copy it to a place the script can access
COPY plugins.txt seed-job-config.xml ./ref/

# Copy your initial setup Groovy scripts
# Scripts in init.groovy.d are executed by the official entrypoint on first run
COPY init.groovy.d/create-seed-job.groovy ./ref/init.groovy.d/

# The base image already defines the correct ENTRYPOINT, no need to override it
ENTRYPOINT ["/usr/local/bin/jenkins-startup.sh"]
