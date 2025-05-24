<<<<<<< HEAD
=======

>>>>>>> 161318eacb6ad0386a9e2677d310b7108ab7f68f
output "kubeconfig_command" {
  description = "Configure kubectl access"
  value       = "aws eks update-kubeconfig --region=${var.aws_region} --name=${var.cluster_name}"
}
