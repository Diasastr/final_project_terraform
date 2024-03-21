/*
  Визначення вхідних змінних для модуля безпеки.
  Дозволяє налаштувати параметри груп безпеки та пар ключів залежно від середовища.
*/

variable "vpc_id" {
  description = "ID VPC, де будуть створені групи безпеки."
  type        = string
}

variable "environment" {
  description = "Назва середовища, яке використовується для тегування ресурсів."
  type        = string
}

variable "instance_connect_ssh_cidr" {
  description = "CIDR блоки для доступу до Jenkins через SSH."
  type        = list(string)
  default     = ["13.48.4.200/30"]
}

data "external" "current_ip" {
  program = ["powershell", "-Command", "$ip = (Invoke-RestMethod -Uri https://icanhazip.com).Trim(); Write-Output \"{`\"ip`\":`\"$ip`\"}\""]
}

variable "jenkins_controller_public_ip" {
  description = "ID інстансу Jenkins контролера."
  type        = string
}

variable "tags" {
  default = ["postgresql", "gitea1", "gitea2"]
}

variable "user" {
  default = "di17"
}

variable "jenkins-sg" {
  default = "jenkins-server-sec-gr-208"
}