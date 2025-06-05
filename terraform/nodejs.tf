# Use a data source to read the existing ingress-nginx service
# This service is created by the GitHub Actions workflow when installing the NGINX Ingress Controller.
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  # No spec is needed for a data source, it just reads the existing resource.
  # Ensure the NGINX Ingress Controller is installed (e.g., by your GitHub Action)
  # before this Terraform code runs or make sure Terraform apply can tolerate its absence initially
  # if the service is not immediately available.
  # Adding an explicit depends_on to a resource that ensures kubectl is configured might be needed
  # if this Terraform runs before the cluster is fully ready for kubectl commands from Terraform.
}

data "aws_elb_service_account" "main" {}

resource "aws_route53_record" "nodejs" {
  zone_id = data.aws_route53_zone.main.zone_id
  ttl     = 300
  name    = "nodejs.bunnycloud.xyz"
  type    = "A"

  alias {
    name                   = data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_elb_service_account.main.zone_id
    evaluate_target_health = true
  }
}
