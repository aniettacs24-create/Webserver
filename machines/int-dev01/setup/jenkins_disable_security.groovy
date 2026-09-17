// jenkins_disable_security.groovy
// Disables Jenkins authentication and authorization on first startup.
// This is intentionally insecure — FOR LAB USE ONLY (vulnerability demo).
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// Disable security completely — anyone can access without login
def strategy = new AuthorizationStrategy.Unsecured()
instance.setAuthorizationStrategy(strategy)

def realm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(realm)

instance.save()
println "[vulncorp] Jenkins security DISABLED — Script Console accessible without auth"
