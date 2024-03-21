/*
  Визначення вхідних змінних для модуля мережевої інфраструктури.
  Забезпечує налаштування параметрів VPC, підмереж, та інших ресурсів.
*/
variable "vpc_cidr" {
  description = "CIDR блок для VPC."
  type        = string
}

variable "public_subnets_cidr" {
  description = "Список CIDR блоків для публічних підмереж."
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "Список CIDR блоків для приватних підмереж."
  type        = list(string)
}

variable "environment" {
  description = "Назва середовища, яке використовується для тегування ресурсів."
  type        = string
}

variable "availability_zones" {
  description = "Список зон доступності для розміщення підмереж."
  type        = list(string)// Note: We do not set a default here because this should be dynamically passed from the root module
}

