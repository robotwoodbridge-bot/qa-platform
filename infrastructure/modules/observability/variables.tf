variable "network_name" { type = string }

variable "loki_version" {
  type    = string
  default = "2.9.0"
}
variable "grafana_version" {
  type    = string
  default = "10.4.2"
}

variable "loki_port" {
  type    = number
  default = 3100
}
variable "grafana_port" {
  type    = number
  default = 3000
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

variable "loki_config_path"          { type = string }
variable "grafana_provisioning_path" { type = string }
