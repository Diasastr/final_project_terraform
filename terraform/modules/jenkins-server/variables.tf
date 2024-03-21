/*
  Визначення вхідних змінних для модуля серверів.
  Дозволяє гнучке налаштування типів інстансів та інших параметрів.
*/

variable "instance_type" {
  description = "Тип EC2 інстансу."
  type        = string
}

variable "environment" {
  description = "Назва середовища для тегування і назв ресурсів."
  type        = string
}

variable "public_subnet_ids" {
  description = "Список ID публічних підмереж для розміщення інстансів."
  type        = list(string)
}

variable "jenkins_security_group_id" {
  description = "ID групи безпеки для Jenkins контролера."
  type        = string
}

variable "jenkins_node_security_group_id" {
  description = "ID групи безпеки для Jenkins контролера."
  type        = string
}

data "aws_ami" "al2023" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "name"
    values = ["al2023-ami-2023*"]
  }
}

variable "private_key_path" {
  description = "Path to the SSH private key"
}

variable "jenkins_instance_profile_name" {
  description = "The name of the IAM instance profile for Jenkins"
  default     = "jenkins_instance_profile"
}

variable "jenkins_node_instance_profile_name" {
  description = "The name of the IAM instance profile for Jenkins node"
  default     = "jenkins_node_instance_profile"
}

variable "tag" {
  default = "Jenkins_Server"
}

variable "jenkins_key_pair_name" {
  type = string
  default = "jenkins-key-pair"
}