pipelineJob('WorkGraph-Pipeline') {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('YOUR_GIT_REPOSITORY_URL') // Replace with your repository URL
                        credentialsId('YOUR_GIT_CREDENTIALS_ID') // Optional: If your repo is private
                    }
                    branch('main') // Or your desired branch
                }
            }
            scriptPath('Jenkinsfile') // Path to your Jenkinsfile in the repository
        }
    }
}
