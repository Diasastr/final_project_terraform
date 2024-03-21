/* Конфігурація Груп Безпеки та Пари Ключів для Інфраструктури Додатків
   Цей модуль налаштовує групи безпеки для доступу за замовчуванням, Jenkins та серверів додатків,
   а також пару ключів для безпечного доступу до інстансів. */

/*==== Група Безпеки за Замовчуванням VPC ======*/
// Група безпеки за замовчуванням для управління вхідним та вихідним трафіком для всього VPC.
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to alloe ingress/egress traffic for VPC"
  vpc_id      = var.vpc_id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  tags = {
    Environment = var.environment
  }
}

/*==== Група Безпеки Jenkins ======*/
// Група безпеки для Jenkins, що дозволяє веб-доступ та обмежений SSH.
resource "aws_security_group" "jenkins_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 50000
    protocol    = "tcp"
    to_port     = 50000
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.instance_connect_ssh_cidr
    description = "Allow SSH for EC2 Instance Connect"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.current_ip.result.ip}/32"]
    description = "Allow SSH for EC2 from my current ip"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = var.jenkins-sg
    Environment = var.environment
    Role        = "jenkins"
  }
}

/*==== Пара Ключів для Розгортання ======*/
# IAM ROLE
resource "aws_iam_role" "jenkins_role" {
      name = "jenkins_role"

      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid    = ""
            Principal = {
              Service = "ec2.amazonaws.com"
            }
          },
        ]
      })
      managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess", "arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/IAMFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonSSMFullAccess"]
    }

# aws ec2 policy is attached
resource "aws_iam_role_policy_attachment" "ec2full_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.jenkins_role.name
}

# aws ecr policy is attached
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.jenkins_role.name
}

# aws vpc policy is attached
resource "aws_iam_role_policy_attachment" "vpc_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  role       =  aws_iam_role.jenkins_role.name
  }

# aws iam policy is attached
resource "aws_iam_role_policy_attachment" "iam_policy" {
  policy_arn =  "arn:aws:iam::aws:policy/IAMFullAccess"
  role       =  aws_iam_role.jenkins_role.name
  }

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name  = "jenkins_instance_profile"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_security_group" "jenkins_node_sg" {
  name        = "jenkins-node-sg"
  description = "Security group for Jenkins node"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id] // Allow SSH from Jenkins controller
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.instance_connect_ssh_cidr
    description = "Allow SSH for EC2 Instance Connect"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-node-sg"
  }
}

resource "aws_iam_role" "jenkins_node_role" {
  name = "jenkins_node_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "jenkins_node_ssm_policy" {
  name   = "jenkins_node_ssm_policy"
  role   = aws_iam_role.jenkins_node_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins_node_instance_profile" {
  name = "jenkins_node_instance_profile"
  role = aws_iam_role.jenkins_node_role.name
}


resource "tls_private_key" "jenkins_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "jenkins_key_pair" {
  key_name   = "jenkins-key-pair"
  public_key = tls_private_key.jenkins_ssh_key.public_key_openssh
}

resource "local_file" "jenkins_private_key" {
  content         = tls_private_key.jenkins_ssh_key.private_key_pem
  filename        = "${path.module}/jenkins-key.pem"
  file_permission = "0600"
}



