# Use the latest LTS Jenkins image with JDK 21
FROM jenkins/jenkins:lts-jdk21

# Set the user to root temporarily to install plugins and make directories
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends wkhtmltoimage xvfb && \
    rm -rf /var/lib/apt/lists/*

# Install Jenkins plugins
# The plugins.txt file is copied from the build context (the jenkins folder)
# The Jenkins entrypoint will automatically install these plugins on first startup
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Skip the initial setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Copy the Groovy init scripts
# The init.groovy.d folder is copied from the build context
# These scripts will be executed by Jenkins on startup
COPY init.groovy.d /usr/share/jenkins/ref/init.groovy.d

# Switch back to the jenkins user
USER jenkins
