locals {
  aws_region_current = [{
    name = data.aws_region.current.name
  }]
}
