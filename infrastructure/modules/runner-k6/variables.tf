variable "network_name" { type = string }
variable "mount_path"   { type = string }

variable "k6_version" {
  type    = string
  default = "latest"
}
