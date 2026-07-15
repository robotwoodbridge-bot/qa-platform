terraform {
  required_version = ">= 1.6"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # Local state — no remote backend needed for local-only usage.
  # To promote to cloud later, replace this block with an s3/gcs/azurerm backend.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {
  # Connects to the local Docker daemon.
  # Override with DOCKER_HOST env var if using a remote socket.
}

locals {
  repo_root  = abspath("${path.module}/../../..")
  docker_dir = abspath("${path.module}/../../docker")
}

module "network" {
  source = "../../modules/network"
}

module "observability" {
  source = "../../modules/observability"

  network_name              = module.network.qa_net_name
  grafana_admin_password    = var.grafana_admin_password
  loki_port                 = var.loki_port
  grafana_port              = var.grafana_port
  loki_config_path          = "${local.docker_dir}/loki-config.yaml"
  grafana_provisioning_path = "${local.docker_dir}/grafana/provisioning"
}

module "runner_playwright" {
  source = "../../modules/runner-playwright"

  network_name        = module.network.qa_net_name
  dockerfile_path     = "${local.docker_dir}/Dockerfile.playwright"
  build_context_path  = local.repo_root
  mount_path           = "${local.repo_root}/testings/gui/playwright"
}

module "runner_robot_web" {
  source = "../../modules/runner-robot-web"

  network_name        = module.network.qa_net_name
  dockerfile_path     = "${local.docker_dir}/Dockerfile.robot-web"
  build_context_path  = local.repo_root
  # Mount the whole robot/ folder, not just web/ — suites reference
  # ../../../shared/resources/*.robot, which lives outside web/.
  mount_path           = "${local.repo_root}/testings/gui/robot"
  image_name          = "qa-platform-robot-web-runner"
  container_name      = "qa-platform-robot-web-runner"
}

module "runner_accessibility" {
  source = "../../modules/runner-robot-web"

  network_name = module.network.qa_net_name
  # Same image logic as runner_robot_web (Browser library / Playwright) — axe-core
  # scans need a real browser, and this is the stack that already has one built
  # and working. Separate container + mount path (not shared with runner_robot_web)
  # so this engine stays independently testable/deployable, same as every other
  # runner here — see testings/accessibility/README.md.
  dockerfile_path     = "${local.docker_dir}/Dockerfile.robot-web"
  build_context_path  = local.repo_root
  mount_path          = "${local.repo_root}/testings/accessibility"
  image_name          = "qa-platform-accessibility-runner"
  container_name      = "qa-platform-accessibility-runner"
}

module "runner_robot_mobile" {
  source = "../../modules/runner-robot-mobile"

  network_name            = module.network.qa_net_name
  client_dockerfile_path  = "${local.docker_dir}/Dockerfile.robot-mobile-client"
  build_context_path      = local.repo_root
  # Same reasoning as runner_robot_web — mount robot/ so shared/ resolves.
  mount_path               = "${local.repo_root}/testings/gui/robot"
  enable_kvm              = var.enable_kvm
}

module "runner_robot_api" {
  source = "../../modules/runner-robot-api"

  network_name        = module.network.qa_net_name
  dockerfile_path     = "${local.docker_dir}/Dockerfile.robot-api"
  build_context_path  = local.repo_root
  # Mount the whole api/ folder (not just rest/) so protocol suites can
  # reference ../../shared/ resources, same reasoning as runner_robot_web.
  mount_path           = "${local.repo_root}/testings/api"
  image_name          = "qa-platform-robot-api-runner"
  container_name      = "qa-platform-robot-api-runner"
}

module "runner_k6" {
  source = "../../modules/runner-k6"

  network_name = module.network.qa_net_name
  mount_path   = "${local.repo_root}/testings/performance/k6"
}

module "runner_security" {
  source = "../../modules/runner-security"

  security_net_name    = module.network.security_net_name
  dockerfile_path      = "${local.docker_dir}/Dockerfile.security"
  build_context_path   = local.repo_root
  # Mount the whole security/ folder, not just zap/ — kali_scan.robot
  # covers ZAP + Nikto + Nmap together and doesn't live under zap/ alone.
  mount_path            = "${local.repo_root}/testings/security"
  additional_networks  = var.security_additional_networks
}

module "pact_broker" {
  source = "../../modules/pact-broker"

  network_name       = module.network.qa_net_name
  pact_broker_port   = var.pact_broker_port
  postgres_password  = var.pact_broker_db_password
}
