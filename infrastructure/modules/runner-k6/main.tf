resource "docker_image" "k6" {
  name         = "grafana/k6:${var.k6_version}"
  keep_locally = true
}

resource "docker_container" "k6" {
  name    = "qa-platform-k6-runner"
  image   = docker_image.k6.image_id
  # grafana/k6's image bakes in ENTRYPOINT ["k6"]. Setting entrypoint = []
  # does NOT reliably clear that with the docker provider — command ends up
  # appended after it instead of replacing it, so the container actually ran
  # `k6 tail -f /dev/null`, which k6 rejects as an unknown subcommand and
  # crash-loops (exit 255) forever. Overriding entrypoint to "tail" itself
  # sidesteps this — command becomes tail's own args. docker exec later
  # invokes `k6` directly (see scripts/run_k6.sh), which is unaffected by
  # what the container's own entrypoint/PID 1 process is.
  entrypoint = ["tail"]
  command    = ["-f", "/dev/null"]

  # grafana/k6's own image WORKDIR is /home/k6, not our mount point — without
  # this, `docker exec qa-platform-k6-runner k6 run scripts/<file>.js` (a
  # relative path, see scripts/run_k6.sh) would resolve against /home/k6 and
  # fail with "no such file", since the test scripts live under the mounted
  # /qa-platform instead.
  working_dir = "/qa-platform"

  networks_advanced {
    name = var.network_name
  }

  volumes {
    host_path      = var.mount_path
    container_path = "/qa-platform"
  }

  restart = "unless-stopped"
}
