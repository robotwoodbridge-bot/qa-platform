output "grafana_url"      { value = "http://localhost:${var.grafana_port}" }
output "pact_broker_url"  { value = module.pact_broker.pact_broker_url }
output "android_novnc_url" { value = module.runner_robot_mobile.novnc_url }
