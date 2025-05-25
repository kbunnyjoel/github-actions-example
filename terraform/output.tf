output "kubeconfig_command" {
  description = "Configure kubectl access"
  value       = "aws eks update-kubeconfig --region=${var.aws_region} --name=${var.cluster_name}"
}
output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_id
}
output "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}
output "eks_cluster_version" {
  description = "EKS Cluster version"
  value       = module.eks.cluster_version
}
output "eks_node_group_names" {
  description = "EKS Node Group names"
  value       = module.eks.eks_managed_node_groups
}
output "eks_node_group_arns" {
  description = "EKS Node Group ARNs"
  value       = [for ng in module.eks.eks_managed_node_groups : ng.arn]
}
output "eks_node_group_instance_types" {
  description = "EKS Node Group instance types"
  value       = [for ng in module.eks.eks_managed_node_groups : ng.instance_types]
}
output "eks_node_group_capacity_types" {
  description = "EKS Node Group capacity types"
  value       = [for ng in module.eks.eks_managed_node_groups : ng.capacity_type]
}
output "eks_vpc_id" {
  description = "VPC ID where EKS is deployed"
  value       = module.vpc.vpc_id
}
output "eks_vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}
output "eks_vpc_public_subnets" {
  description = "Public subnets in the VPC"
  value       = module.vpc.public_subnets
}
output "eks_vpc_private_subnets" {
  description = "Private subnets in the VPC"
  value       = module.vpc.private_subnets
}
output "eks_vpc_azs" {
  description = "Availability Zones in the VPC"
  value       = module.vpc.availability_zones
}
output "eks_vpc_dns_support" {
  description = "DNS support enabled in the VPC"
  value       = module.vpc.enable_dns_support
}
output "eks_vpc_dns_hostnames" {
  description = "DNS hostnames enabled in the VPC"
  value       = module.vpc.enable_dns_hostnames
}
output "eks_vpc_tags" {
  description = "Tags applied to the VPC"
  value       = module.vpc.tags
}
output "eks_vpc_public_subnet_tags" {
  description = "Tags applied to public subnets"
  value       = module.vpc.public_subnet_tags
}
output "eks_vpc_private_subnet_tags" {
  description = "Tags applied to private subnets"
  value       = module.vpc.private_subnet_tags
}
output "eks_vpc_internet_gateway_id" {
  description = "Internet Gateway ID for the VPC"
  value       = module.vpc.internet_gateway_id
}
output "eks_vpc_nat_gateway_ids" {
  description = "NAT Gateway IDs for the VPC"
  value       = module.vpc.nat_gateway_ids
}
output "eks_vpc_route_table_ids" {
  description = "Route Table IDs for the VPC"
  value       = module.vpc.route_table_ids
}
output "eks_vpc_route_table_association_ids" {
  description = "Route Table Association IDs for the VPC"
  value       = module.vpc.route_table_association_ids
}
output "eks_vpc_security_group_ids" {
  description = "Security Group IDs for the VPC"
  value       = module.vpc.vpc_default_security_group_id
}
output "eks_vpc_security_group_rules" {
  description = "Security Group rules for the VPC"
  value       = module.vpc.vpc_default_security_group_rules
}
output "eks_vpc_flow_logs" {
  description = "VPC Flow Logs configuration"
  value       = module.vpc.vpc_flow_logs
}
output "eks_vpc_flow_logs_enabled" {
  description = "Are VPC Flow Logs enabled?"
  value       = module.vpc.vpc_flow_logs_enabled
}
output "eks_vpc_flow_logs_bucket" {
  description = "S3 bucket for VPC Flow Logs"
  value       = module.vpc.vpc_flow_logs_bucket
}
