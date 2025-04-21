// Groovy Initialization Script: setup-admin.groovy
// This script runs automatically during Jenkins startup.
// Its purpose is to create an initial administrator user if one does not exist.
// This is part of automating the initial Jenkins setup in a Docker container.

import jenkins.model.*
import hudson.security.*
import hudson.model.User // Import the User class

println("--- Running setup-admin.groovy ---")

try {
    def instance = Jenkins.getInstance()

    // Define the admin user details.
    def admin_user = "admin"
    def admin_password = System.getenv("JENKINS_ADMIN_PASSWORD")
    def admin_email = "admin@example.com" // Optional

    // Validate that a password is available
    if (admin_password == null || admin_password.isEmpty()) {
        println("WARNING: JENKINS_ADMIN_PASSWORD environment variable not set. Using a default password. PLEASE SET A SECURE PASSWORD IN docker-compose.yml!")
        admin_password = "your_secure_default_password" // **Change this default if not using the env var**
         if (admin_password == "your_secure_default_password") {
             println("ERROR: Default password in setup-admin.groovy is unchanged. Please set JENKINS_ADMIN_PASSWORD or change the default.")
             // Optionally, exit the script or throw an error if a secure password is not set.
             // return // Exit script if password is not set securely
         }
    }

    // Get the current security realm
    def realm = instance.getSecurityRealm()

    // Check if the security realm is HudsonPrivateSecurityRealm
    if (realm instanceof HudsonPrivateSecurityRealm) {
        def hudsonRealm = realm as HudsonPrivateSecurityRealm

        // Check if the admin user already exists
        def user = User.getById(admin_user, false) // Use false to not create if not exists

        if (user == null) {
            // User does not exist, create the account and set the password
            println("Admin user '${admin_user}' not found. Creating user...")
            hudsonRealm.createAccount(admin_user, admin_password)
            user = User.getById(admin_user, false) // Get the newly created user object

            if (user != null) {
                 user.setFullName(admin_user)
                 // Add user properties if needed (MailerProperty commented out previously)
                 // try {
                 //     user.addProperty(new hudson.security.MailerProperty(admin_email))
                 //     println("Added MailerProperty to user '${admin_user}'.")
                 // } catch (e) {
                 //     println("Could not add MailerProperty: ${e.getMessage()}")
                 // }
                 user.save() // Save user changes
                 println("Admin user '${admin_user}' created and configured.")
            } else {
                 println("ERROR: Failed to retrieve user object after creation attempt.")
            }

        } else {
            println("Admin user '${admin_user}' already exists. Skipping creation.")
            // Optional: Update password or properties if needed, but be cautious on restarts
            // user.setPassword(admin_password) // Uncomment with caution!
            // user.save() // Uncomment with caution!
            // println("Admin user '${admin_user}' already exists. Password potentially updated.")
        }

        // Ensure the authorization strategy is set (this part was correct)
        def strategy = instance.getAuthorizationStrategy()
        if (!(strategy instanceof FullControlOnceLoggedInAuthorizationStrategy)) {
             println("Setting FullControlOnceLoggedInAuthorizationStrategy.")
             instance.setAuthorizationStrategy(new FullControlOnceLoggedInAuthorizationStrategy())
             instance.save()
        } else {
             println("FullControlOnceLoggedInAuthorizationStrategy is already set.")
        }


    } else {
        println("Current security realm is not HudsonPrivateSecurityRealm. Skipping admin user creation via script.")
        println("Current realm: ${realm?.getClass()?.getName()}")
    }

    instance.save() // Save overall Jenkins configuration changes

    println("Jenkins setup script completed.")

} catch (e) {
    println("Error during setup-admin.groovy execution: ${e.getMessage()}")
    e.printStackTrace() // Print stack trace for detailed debugging
}

println("--- Finished setup-admin.groovy ---")
