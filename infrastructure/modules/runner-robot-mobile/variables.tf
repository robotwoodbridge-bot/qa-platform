variable "network_name"    { type = string }
variable "client_dockerfile_path"    { type = string }
variable "build_context_path"        { type = string }
variable "mount_path"                { type = string }

variable "android_image" {
  type    = string
  default = "budtmo/docker-android:emulator_11.0"
}

variable "enable_kvm" {
  description = "Requires /dev/kvm on the host (Linux, or nested virt on a cloud VM). Emulator runs unaccelerated (slow) if false."
  type    = bool
  default = false
}

variable "novnc_port" {
  type    = number
  default = 6080
}
variable "appium_port" {
  type    = number
  default = 4723
}
