output "vpc_id" {
  description = "ID створеного VPC."
  value       = module.networking.vpc_id
}

output "public_subnets_ids" {
  description = "ID публічних підмереж."
  value       = module.networking.public_subnets_ids
}
