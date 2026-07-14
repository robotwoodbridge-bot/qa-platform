# General-purpose network for test runners, observability, and the pact
# broker. Everything EXCEPT the security/Kali runner lives here.
resource "docker_network" "qa_net" {
  name   = var.qa_net_name
  driver = "bridge"
}

# Isolated network for security scanning (Kali/ZAP). Deliberately NOT
# connected to qa_net by default. Attach the security runner to a specific
# target network only for the duration of an explicit, authorized scan —
# see modules/runner-security/README.md.
resource "docker_network" "security_net" {
  name   = var.security_net_name
  driver = "bridge"
}
