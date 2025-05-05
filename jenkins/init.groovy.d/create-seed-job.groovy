// File: init.groovy.d/create-seed-job.groovy
import jenkins.model.*
import hudson.model.*
import java.io.ByteArrayInputStream

def jenkins = Jenkins.instance

// Define the job name
def jobName = "job-dsl-seed"
// Path to the job config XML copied in the Dockerfile
def configXmlPath = "/usr/share/jenkins/ref/seed-job-config.xml"

println "Jenkins init script: Checking for job '${jobName}'"

// Check if the job already exists
if (jenkins.getItem(jobName) == null) {
    println "Jenkins init script: Creating job '${jobName}' from ${configXmlPath}"
    try {
        def configXml = new File(configXmlPath).getText("UTF-8")
        jenkins.createProjectFromXML(jobName, new ByteArrayInputStream(configXml.getBytes("UTF-8")))
        println "Jenkins init script: Job '${jobName}' created successfully."

        // Optional: Trigger the seed job after creation
        // println "Jenkins init script: Triggering job '${jobName}'"
        // def newJob = jenkins.getItem(jobName)
        // if (newJob != null) {
        //     newJob.scheduleBuild(0)
        // } else {
        //     println "Jenkins init script: Could not find newly created job to trigger."
        // }

    } catch (Exception e) {
        println "Jenkins init script: Error creating job '${jobName}': ${e.getMessage()}"
        e.printStackTrace()
    }
} else {
    println "Jenkins init script: Job '${jobName}' already exists, skipping creation."
}
