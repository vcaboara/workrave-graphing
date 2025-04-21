# Workrave Stats Visualizer

This application parses Workrave statistics and generates ~dynamic~ (eventually) graphs.

## Usage

1.  Run `docker-compose up --build`.

## Development

WIP

## CI/CD

WIP

## Pre-commit hooks

```
pre-commit run --all-files # Run on all files
pre-commit run --files app/app.py # Run on a specific file
```
## Jenkins Server Setup via Configuration as Code (JCasC)

This section outlines how to use the provided configuration files (`jenkins.yaml` and `seed_job.groovy`) to set up a Jenkins server instance capable of running the WorkGraph pipeline.

**Prerequisites:**

* Java installed on your system.
* Docker installed on the machine where Jenkins will run (or accessible by it).
* Git installed on the machine where Jenkins will run.

**Steps:**

1.  **Save `jenkins.yaml`:** Place the `jenkins.yaml` file on the server where you intend to run Jenkins.

2.  **Start Jenkins with JCasC:** Launch the Jenkins server, instructing it to use the `jenkins.yaml` configuration file. This can be done via an environment variable or a system property:

    ```bash
    # Using environment variable (before running jenkins.war)
    export JENKINS_CONFIG_FILES=/path/to/your/jenkins.yaml
    java -jar jenkins.war

    # Using system property (when running jenkins.war)
    java -Djenkins.config.file=/path/to/your/jenkins.yaml -jar jenkins.war
    ```

Replace `/path/to/your/jenkins.yaml` with the actual path to the file.

3.  **Initial Setup (if first run):**
    * Jenkins might prompt for an initial admin password (usually found in the Jenkins logs or a file in the Jenkins home directory).
    * If JCasC is correctly configured, it will apply the settings from `jenkins.yaml`, including the admin user. Log in with the username `admin` and the password you set in `jenkins.yaml` (or the default `admin` if you didn't change it yet). **Change the default password immediately via the Jenkins UI (`Manage Jenkins` -> `Manage Users`).**

4.  **Save `seed_job.groovy`:** Place the `seed_job.groovy` file in your Git repository (e.g., at the root or in a `jenkins` subdirectory).

5.  **Create Seed Job in Jenkins:**
    * In the Jenkins UI, create a **new item**.
    * Choose **Pipeline** as the job type and give it a name (e.g., `WorkGraph-Seed-Job`).
    * In the **Pipeline** section, select **Pipeline script from SCM**.
    * Configure your **SCM** (usually Git):
        * **Repository URL:** Enter the URL of your Git repository.
        * **Credentials (optional):** If your repository is private, configure and select the appropriate Jenkins credentials.
        * **Branch:** Specify the branch where `seed_job.groovy` resides (e.g., `main`).
        * **Script Path:** Enter the path to the `seed_job.groovy` file within the repository (e.g., `seed_job.groovy` or `jenkins/seed_job.groovy`).
    * Save the seed job.

6.  **Run the Seed Job:** Manually run the `WorkGraph-Seed-Job` in Jenkins. This job will execute the Groovy script and create the `WorkGraph-Pipeline` job based on your `Jenkinsfile`.

7.  **Run the WorkGraph Pipeline:** Once the seed job completes successfully, you will find a new job named `WorkGraph-Pipeline` in your Jenkins instance. You can then configure and run this pipeline to build your Docker image and generate the Workrave graph.
