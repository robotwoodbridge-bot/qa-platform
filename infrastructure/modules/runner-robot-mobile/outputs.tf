output "appium_url"        { value = "http://${docker_container.android_emulator.name}:4723" }
output "novnc_url"         { value = "http://localhost:${var.novnc_port}" }
output "client_container"  { value = docker_container.client.name }
