variable "security_net_name"  { type = string }
variable "dockerfile_path"    { type = string }
variable "build_context_path" { type = string }
variable "mount_path"         { type = string }

variable "additional_networks" {
  description = "Extra networks to attach for the duration of an explicit, authorized scan. Leave empty by default — do not leave attached long-term."
  type    = list(string)
  default = []
}
