locals {
  aws_region_current = [{
    name = data.aws_region.current.name
  }]
  oidc_provider_url = replace(module.eks.oidc_provider, "https://", "")
}
