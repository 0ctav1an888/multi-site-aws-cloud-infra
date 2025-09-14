# Llanelli Outputs
output "llanelli_vpc_id" {
  description = "Llanelli VPC ID"
  value = try(module.llanelli.vpc_id, null)
}

output "llanelli_public_subnets_ids" {
  description = "List of Llanelli Public Subnet IDs"
  value = try(module.llanelli.public_subnet_ids, [])
}

output "llanelli_private_subnet_ids" {
  description = "List of Llanelli Private Subnet IDS"
  value = try(module.llanelli.private_subnets_ids, [])
}

output "llanelli_management_subnet_ids" {
  description = "Llanelli Management Subnet ID"
  value = try(module.llanelli_management_subnet_id, null)
}

# Cardiff Outputs

output "cardiff_vpc_id" {
  description = "cardiff VPC ID"
  value = try(module.cardiff.vpc_id, null)
}

output "cardiff_public_subnets_ids" {
  description = "List of cardiff Public Subnet IDs"
  value = try(module.cardiff.public_subnet_ids, [])
}

output "cardiff_private_subnet_ids" {
  description = "List of cardiff Private Subnet IDS"
  value = try(module.cardiff.private_subnets_ids, [])
}

output "cardiff_management_subnet_ids" {
  description = "cardiff Management Subnet ID"
  value = try(module.cardiff_management_subnet_id, null)
}