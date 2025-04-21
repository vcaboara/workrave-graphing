// /usr/share/jenkins/ref/init.groovy.d/setup-admin.groovy
// This script runs on Jenkins startup to create an initial admin user

import jenkins.model.*
import hudson.security.*
//import hudson.security.MailerProperty

def instance = Jenkins.getInstance()

// Define the admin user details
// It's highly recommended to use an environment variable for the password in production
def admin_user = "admin"
def admin_password = System.getenv("JENKINS_ADMIN_PASSWORD") ?: "your_secure_password" // **Change "your_secure_password" or ensure JENKINS_ADMIN_PASSWORD env var is set**
def admin_email = "admin@example.com" // Optional: Change to your desired email

// Set up a basic security realm and authorization strategy
// This is a simple setup; you might need a more robust configuration for production
def realm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(realm)

// Create the admin user
def user = realm.getOrCreateUser(admin_user) // Use getOrCreateUser
user.setFullName(admin_user)
//user.addProperty(new hudson.security.MailerProperty(admin_email))
user.setPassword(admin_password)

// Assign admin privileges
// This strategy gives full control to logged-in users; adjust as needed
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)

// Save the configuration
instance.save()

println("Jenkins admin user '${admin_user}' creation script executed.")
