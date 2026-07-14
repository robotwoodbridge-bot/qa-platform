output "qa_net_name" {
  value = docker_network.qa_net.name
}

output "security_net_name" {
  value = docker_network.security_net.name
}
