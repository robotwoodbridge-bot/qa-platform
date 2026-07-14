resource "docker_image" "k6" {
  name         = "grafana/k6:${var.k6_version}"
  keep_locally = true
}

resource "docker_container" "k6" {
  name    = "qa-platform-k6-runner"
  image   = docker_image.k6.image_id
  command = ["tail", "-f", "/dev/null"] # scripts launched via: docker exec qa-platform-k6-runner k6 run scripts/<file>.js
  entrypoint = []

  networks_advanced {
    name = var.network_name
  }

  volumes {
    host_path      = var.mount_path
    container_path = "/qa-platform"
  }

  restart = "unless-stopped"
}
