/*
  Визначення вихідних даних для модуля серверів.
  Надає доступ до важливої інформації про створені EC2 інстанси.
*/

// ID Jenkins контролера
output "jenkins_controller_id" {
  description = "ID інстансу Jenkins контролера."
  value       = aws_instance.jenkins_controller.id
}

// Публічна IP адреса Jenkins контролера
output "jenkins_controller_public_ip" {
  description = "Публічна IP адреса інстансу Jenkins контролера."
  value       = aws_instance.jenkins_controller.public_ip
}

output "jenkins-server" {
  value = "http://${aws_instance.jenkins_controller.public_dns}:8080"
}

output "jenkins_node_ip" {
  value = aws_instance.jenkins_node.public_ip
}
