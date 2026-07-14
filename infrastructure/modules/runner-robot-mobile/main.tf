# Android emulator + Appium server, using the community budtmo/docker-android
# image rather than building one from scratch. A separate lightweight
# "client" container runs Robot Framework + AppiumLibrary and drives the
# emulator over the network via the Appium endpoint below.
#
# iOS is intentionally NOT scaffolded here: Apple restricts Xcode/Simulator
# to macOS, so it cannot run in a Linux Docker container. When ready, add
# an external macOS runner (local Mac, MacStadium, GitHub-hosted macOS
# runner) and point a new robot/mobile/ios client at it the same way this
# module points at the Android emulator.
resource "docker_image" "android_emulator" {
  name         = var.android_image
  keep_locally = true
}

resource "docker_container" "android_emulator" {
  name       = "qa-platform-android-emulator"
  image      = docker_image.android_emulator.image_id
  privileged = true

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = 6080
    external = var.novnc_port # noVNC — watch the emulator screen in a browser
  }

  ports {
    internal = 4723
    external = var.appium_port
  }

  dynamic "devices" {
    for_each = var.enable_kvm ? [1] : []
    content {
      host_path      = "/dev/kvm"
      container_path = "/dev/kvm"
    }
  }

  env = [
    "EMULATOR_DEVICE=Samsung Galaxy S10",
    "WEB_VNC=true",
    "APPIUM=true",
  ]

  restart = "unless-stopped"
}

resource "null_resource" "client_build" {
  triggers = {
    dockerfile   = filemd5(var.client_dockerfile_path)
    requirements = filemd5("${var.build_context_path}/infrastructure/docker/requirements-robot-mobile.txt")
    image_tag    = "qa-platform-robot-mobile-client:latest"
  }

  provisioner "local-exec" {
    command     = "docker build -t qa-platform-robot-mobile-client:latest -f ${var.client_dockerfile_path} ."
    working_dir = var.build_context_path
  }
}

resource "docker_image" "client" {
  name         = "qa-platform-robot-mobile-client:latest"
  keep_locally = true
  depends_on   = [null_resource.client_build]
}

resource "docker_container" "client" {
  name    = "qa-platform-robot-mobile-client"
  image   = docker_image.client.image_id
  command = ["tail", "-f", "/dev/null"]

  networks_advanced {
    name = var.network_name
  }

  volumes {
    host_path      = var.mount_path
    container_path = "/qa-platform"
  }

  env = [
    "APPIUM_URL=http://qa-platform-android-emulator:4723",
  ]

  restart = "unless-stopped"

  lifecycle {
    replace_triggered_by = [null_resource.client_build]
  }

  depends_on = [docker_container.android_emulator]
}
