output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "web_sg_id" {
  value = aws_security_group.web.id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "listener_arn" {
  value = aws_lb_listener.https.arn
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}