resource "docker_volume" "pact_broker_db" {
  name = "pact-broker-db"
}

resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_image" "pact_broker" {
  name         = "pactfoundation/pact-broker:latest"
  keep_locally = true
}

resource "docker_container" "postgres" {
  name  = "qa-platform-pact-broker-db"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = var.network_name
  }

  env = [
    "POSTGRES_DB=pact_broker",
    "POSTGRES_USER=pact_broker",
    "POSTGRES_PASSWORD=${var.postgres_password}",
  ]

  volumes {
    volume_name    = docker_volume.pact_broker_db.name
    container_path = "/var/lib/postgresql/data"
  }

  restart = "unless-stopped"
}

resource "docker_container" "pact_broker" {
  name  = "qa-platform-pact-broker"
  image = docker_image.pact_broker.image_id

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = 9292
    external = var.pact_broker_port
  }

  env = [
    "PACT_BROKER_DATABASE_ADAPTER=postgres",
    "PACT_BROKER_DATABASE_HOST=qa-platform-pact-broker-db",
    "PACT_BROKER_DATABASE_NAME=pact_broker",
    "PACT_BROKER_DATABASE_USERNAME=pact_broker",
    "PACT_BROKER_DATABASE_PASSWORD=${var.postgres_password}",
    "PACT_BROKER_PORT=9292",
  ]

  depends_on = [docker_container.postgres]
  restart    = "unless-stopped"
}
