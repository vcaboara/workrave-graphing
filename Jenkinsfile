pipeline {
    agent { docker { image 'docker:dind' } }
    stages {
        stage('Pre-commit') {
            steps {
                sh 'pip install pre-commit'
                sh 'pre-commit run --all-files'
            }
        }
        stage('Build') {
            steps {
                sh 'docker build -t your-dockerhub-username/workrave-stats-visualizer .'
            }
        }
        stage('Push') {
            steps {
                sh 'docker login -u "$DOCKER_HUB_USER" -p "$DOCKER_HUB_PASSWORD"'
                sh 'docker push your-dockerhub-username/workrave-stats-visualizer'
            }
        }
    }
    environment {
        DOCKER_HUB_USER = credentials('dockerhub-username').username
        DOCKER_HUB_PASSWORD = credentials('dockerhub-password').password
    }
}
