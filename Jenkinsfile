pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Archive Job State - Pre') {
            steps {
                script {
                    // TODO: Implement headless browser screenshot of Jenkins job page
                    echo "// TODO: Capture screenshot of Jenkins job page (before and after run)"
                }
            }
        }

        // TODO: Python and Windows 2022 LTSC docker images
        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "workgraph:${env.BUILD_ID}"
                    docker build -t "${imageName}" .
                    env.DOCKER_IMAGE = imageName
                }
            }
        }

        // TODO: Generate graph via both built docker images
        stage('Run and Generate Graph') {
            steps {
                script {
                    // Ensure output directory exists in Jenkins workspace
                    sh 'mkdir -p output'
                    docker run --rm -v "${WORKSPACE}/output:/app/output" "${env.DOCKER_IMAGE}"
                }
            }
        }

        // TODO: Can compare the graphs before archiving
        stage('Archive Graph') {
            steps {
                archiveArtifacts 'output/mouse_activity.png'
            }
        }

        stage('Archive Job State - Post') {
            steps {
                script {
                    // TODO: Implement headless browser screenshot of Jenkins job page
                    echo "// TODO: Capture screenshot of Jenkins job page (before and after run)"
                }
            }
        }
    }

    post {
        always {
            script {
                // TODO: Implement logic to archive the Jenkins job state screenshot
                echo "// TODO: Archive the Jenkins job state screenshot"
            }
        }
    }
}

// TODO: Add stage for Unit Tests
// TODO: Add stage for Linting and Static Analysis
// TODO: Explore creating a slideshow/animation of job evolution
