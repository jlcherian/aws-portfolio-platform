output "alb_dns" {
  value = module.compute.alb_dns_name
}

output "app_url" {
  value = "https://app.cloudpfbuildguide.click"
}
