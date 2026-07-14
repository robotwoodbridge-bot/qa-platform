# Kali + OWASP ZAP. Lives on its own isolated network by default (see
# modules/network) — NOT connected to the general net-qa-platform network.
# See README.md for why, and how to attach a scan target for an authorized
# session.
resource "null_resource" "build" {
  triggers = {
    dockerfile   = filemd5(var.dockerfile_path)
    requirements = filemd5("${var.build_context_path}/infrastructure/docker/requirements-robot-security.txt")
    image_tag    = "qa-platform-security-runner:latest"
  }

  provisioner "local-exec" {
    command     = "docker build -t qa-platform-security-runner:latest -f ${var.dockerfile_path} ."
    working_dir = var.build_context_path
  }
}

resource "docker_image" "this" {
  name         = "qa-platform-security-runner:latest"
  keep_locally = true
  depends_on   = [null_resource.build]
}

resource "docker_container" "this" {
  name    = "qa-platform-security-runner"
  image   = docker_image.this.image_id
  command = ["tail", "-f", "/dev/null"]

  networks_advanced {
    name = var.security_net_name
  }

  dynamic "networks_advanced" {
    for_each = var.additional_networks
    content {
      name = networks_advanced.value
    }
  }

  volumes {
    host_path      = var.mount_path
    container_path = "/qa-platform"
  }

  # security.robot shells out `docker run --rm` per scan (ZAP/Nikto/Nmap as
  # ephemeral sibling containers) rather than using CLI tools installed in
  # this image. Requires the host Docker socket. This is an accepted
  # tradeoff against the network-isolation goal above — see README.md.
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  # security.robot's `docker run -v ...` calls go through the socket above,
  # so they're resolved by the HOST daemon against the HOST filesystem —
  # a path like /qa-platform/... (this container's own mount point) means
  # nothing there. Pass the real host path in so the keywords can build
  # host-valid -v sources instead.
  env = [
    "HOST_MOUNT_ROOT=${var.mount_path}",
  ]

  restart = "unless-stopped"

  lifecycle {
    replace_triggered_by = [null_resource.build]
  }
}
