variable "argocd_lb_ip" {
  description = "IP address of the ArgoCD LoadBalancer"
  type        = string
  default     = "0.0.0.0" # Default placeholder IP
}

resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "argocd"
  type    = "A"
  ttl     = 60
  records = [var.argocd_lb_ip]
}