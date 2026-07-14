variable "network_name"       { type = string }
variable "dockerfile_path"    { type = string }
variable "build_context_path" { type = string }
variable "mount_path"         { type = string }
variable "image_name" {
  type    = string
  default = "qa-platform-robot-web-runner"
}
variable "container_name" {
  type    = string
  default = "qa-platform-robot-web-runner"
}
variable "loki_enabled" {
  type    = bool
  default = true
}
