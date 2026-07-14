variable "network_name"       { type = string }
variable "pact_broker_port" {
  type    = number
  default = 9292
}
variable "postgres_password" {
  type      = string
  sensitive = true
}
