# 2 crit and 2 high sev vulnerabilites
FROM jenkins/jenkins:lts-jdk21

USER root

# Install dependencies for wkhtmltoimage, wget, and potentially curl if create_seed_job.sh uses it
# Ensure curl is installed if your wait logic or job creation script relies on it.
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Define wkhtmltox version and download/install manually
ENV WKHTMLTOX_VER="0.12.6.1-3"
ENV WKHTMLTOX_FILENAME="wkhtmltox_${WKHTMLTOX_VER}.bookworm_amd64.deb"
ENV WKHTMLTOX_URL="https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOX_VER}/${WKHTMLTOX_FILENAME}"
RUN echo "Downloading ${WKHTMLTOX_FILENAME} from ${WKHTMLTOX_URL}" \
    && wget "${WKHTMLTOX_URL}" -O /tmp/${WKHTMLTOX_FILENAME} \
    && echo "Download complete." \
    && echo "Installing ${WKHTMLTOX_FILENAME} and dependencies..." \
    && apt-get update \
    && apt-get install -y /tmp/${WKHTMLTOX_FILENAME} \
    && echo "Installation complete." \
    && rm /tmp/${WKHTMLTOX_FILENAME} \
    && rm -rf /var/lib/apt/lists/*

# Install Jenkins plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Copy Groovy init scripts
COPY init.groovy.d /usr/share/jenkins/ref/init.groovy.d

ENV START_SCRIPT=jenkins-startup.sh \
    CREATE_SCRIPT=create-seed-job.sh \
    USR_BIN=/usr/local/bin
# Copy the wrapper startup script and the job creation script
# Make sure create_seed_job.sh exists in the same directory as your Dockerfile (./jenkins/)
# Assuming you use the shell script for job creation
COPY ${START_SCRIPT} ${CREATE_SCRIPT} seed-job-config.xml ${USR_BIN}/

# Make the scripts executable
RUN chmod +x ${USR_BIN}/${START_SCRIPT} \
	&& chmod +x ${USR_BIN}/${CREATE_SCRIPT}

# Switch back to the jenkins user
USER jenkins

# Set the wrapper script as the command to run when the container starts
# This replaces the default Jenkins entrypoint/cmd
# CMD ["/usr/local/bin/jenkins-startup.sh"]
ENTRYPOINT ["/usr/local/bin/jenkins-startup.sh"]
