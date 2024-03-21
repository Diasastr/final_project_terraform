/* Jenkins Controller */
// Ресурс EC2 інстансу для Jenkins контролера та jenkins agent. Використовує останній AMI Ubuntu.


resource "aws_instance" "jenkins_controller" {
  ami                    = data.aws_ami.al2023.id // ID останнього AMI Amazon Linux
  instance_type          = var.instance_type // Тип інстансу, визначений у змінній.
  subnet_id              = element(var.public_subnet_ids, 0) // Підмережа для розміщення інстансу.
  key_name               = var.jenkins_key_pair_name // Назва ключа EC2 для доступу.
  vpc_security_group_ids = [var.jenkins_security_group_id] // ID групи безпеки Jenkins.
  iam_instance_profile = var.jenkins_instance_profile_name
  depends_on = [var.private_key_path]

  tags = {
    Name = var.tag
    Environment = var.environment
    Role        = "jenkins"
  }

  connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }

  provisioner "file" {
    source      = "modules/jenkins-server/setup-jenkins.yml"
    destination = "/home/ec2-user/setup-jenkins.yml"
  }

  provisioner "file" {
    source      = "modules/jenkins-server/jenkins-ssh-credential.xml.j2"
    destination = "/home/ec2-user/jenkins-ssh-credential.xml.j2"
  }

  provisioner "file" {
    source      = "modules/jenkins-server/jenkins.sh"
    destination = "/home/ec2-user/jenkins.sh"
  }

  provisioner "file" {
    source      = var.private_key_path
    destination = "/home/ec2-user/jenkins-key.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/jenkins.sh",
      "sudo /home/ec2-user/jenkins.sh",
      "chmod 600 /home/ec2-user/jenkins-key.pem"
    ]
  }
}

/* Jenkins Node (Agent) */
resource "aws_instance" "jenkins_node" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = element(var.public_subnet_ids, 0) // Adjust as necessary
  key_name               = var.jenkins_key_pair_name
  vpc_security_group_ids = [var.jenkins_node_security_group_id]
  iam_instance_profile   = var.jenkins_node_instance_profile_name
  depends_on = [aws_instance.jenkins_controller]

  tags = {
    Name        = "${var.tag}-node"
    Environment = var.environment
    Role        = "jenkins-node"
  }
  user_data = templatefile("${path.module}/jenkinsnode.tpl", {
    controller_ip = aws_instance.jenkins_controller.public_ip,
    DockerComposeVersion = "1.29.2",
    TerraformVersion = "1.6.2"
  })

}


