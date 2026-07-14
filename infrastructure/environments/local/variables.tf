variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

variable "pact_broker_db_password" {
  type      = string
  sensitive = true
}

variable "loki_port" {
  type    = number
  default = 3100
}
variable "grafana_port" {
  type    = number
  default = 3000
}
variable "pact_broker_port" {
  type    = number
  default = 9292
}

variable "enable_kvm" {
  description = "Requires /dev/kvm on the host. See modules/runner-robot-mobile/README.md."
  type    = bool
  default = false
}

variable "security_additional_networks" {
  description = "Do not set by default. Only for the duration of an authorized scan — see modules/runner-security/README.md."
  type    = list(string)
  default = []
}
