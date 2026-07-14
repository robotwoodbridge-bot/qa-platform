resource "docker_volume" "grafana_storage" {
  name = "grafana-storage"
}

resource "docker_volume" "loki_storage" {
  name = "loki-storage"
}

resource "docker_image" "loki" {
  name         = "grafana/loki:${var.loki_version}"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:${var.grafana_version}"
  keep_locally = true
}

resource "docker_container" "loki" {
  name  = "qa-platform-loki"
  image = docker_image.loki.image_id

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = 3100
    external = var.loki_port
  }

  volumes {
    host_path      = var.loki_config_path
    container_path = "/etc/loki/local-config.yaml"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.loki_storage.name
    container_path = "/loki"
  }

  command = ["-config.file=/etc/loki/local-config.yaml"]

  healthcheck {
    test         = ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3100/ready"]
    interval     = "15s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }

  restart = "unless-stopped"
}

resource "docker_container" "grafana" {
  name  = "qa-platform-grafana"
  image = docker_image.grafana.image_id

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = 3000
    external = var.grafana_port
  }

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
  ]

  volumes {
    volume_name    = docker_volume.grafana_storage.name
    container_path = "/var/lib/grafana"
  }

  volumes {
    host_path      = var.grafana_provisioning_path
    container_path = "/etc/grafana/provisioning"
    read_only      = true
  }

  depends_on = [docker_container.loki]
  restart    = "unless-stopped"
}
