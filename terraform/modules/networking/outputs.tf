/*
  Визначення вихідних змінних для модуля мережевої інфраструктури.
  Забезпечує доступ до ключової інформації про створені ресурси.
*/

output "vpc_id" {
  description = "ID створеного VPC."
  value       = aws_vpc.vpc.id
}

output "public_subnets_ids" {
  description = "ID публічних підмереж."
  value       = aws_subnet.public_subnet.*.id
}

output "private_subnets_ids" {
  description = "ID приватних підмереж."
  value       = aws_subnet.private_subnet.*.id
}

output "public_route_table_id" {
  description = "ID таблиці маршрутизації для публічних підмереж."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID таблиці маршрутизації для приватних підмереж."
  value       = aws_route_table.private.id
}
