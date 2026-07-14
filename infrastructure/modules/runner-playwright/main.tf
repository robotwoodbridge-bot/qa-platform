# Web GUI runner — Playwright/TypeScript only. Robot Framework and
# security tooling live in their own modules now (see runner-robot-web,
# runner-robot-mobile, runner-security) instead of being bundled into one
# combined image.
resource "null_resource" "build" {
  triggers = {
    dockerfile = filemd5(var.dockerfile_path)
    image_tag  = "${var.image_name}:latest"
  }

  provisioner "local-exec" {
    command     = "docker build -t ${var.image_name}:latest -f ${var.dockerfile_path} ."
    working_dir = var.build_context_path
  }
}

resource "docker_image" "this" {
  name         = "${var.image_name}:latest"
  keep_locally = true
  depends_on   = [null_resource.build]
}

resource "docker_container" "this" {
  name    = var.container_name
  image   = docker_image.this.image_id
  command = ["tail", "-f", "/dev/null"]

  networks_advanced {
    name = var.network_name
  }

  volumes {
    host_path      = var.mount_path
    container_path = "/qa-platform"
  }

  env = [
    "LOKI_URL=http://qa-platform-loki:3100/loki/api/v1/push",
    "LOKI_ENABLED=${var.loki_enabled}",
  ]

  restart = "unless-stopped"

  lifecycle {
    replace_triggered_by = [null_resource.build]
  }
}
