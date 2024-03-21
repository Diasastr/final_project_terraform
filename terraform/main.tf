/* Модуль мережі */
// Цей модуль налаштовує всю мережеву інфраструктуру, включаючи VPC, публічні та приватні підмережі.

module "networking" {
  source               = "./modules/networking"
  vpc_cidr             = var.vpc_cidr // CIDR блок для VPC.
  public_subnets_cidr  = var.public_subnets_cidr // Список CIDR блоків для публічних підмереж.
  private_subnets_cidr = var.private_subnets_cidr // Список CIDR блоків для приватних підмереж.
  environment          = var.environment // Назва середовища розгортання.
  availability_zones   = local.availability_zones // Список зон доступності, визначений локально.
}

/* Модуль безпеки */
// Налаштовує групи безпеки і ключі доступу для інстансів.
module "security" {
  source                   = "./modules/security"
  vpc_id                   = module.networking.vpc_id // ID VPC, створеного модулем мережі.
  environment              = var.environment
  instance_connect_ssh_cidr = var.instance_connect_ssh_cidr // CIDR блоки для SSH доступу.
  jenkins_controller_public_ip = module.jenkins-server.jenkins_controller_public_ip
}

/* Модуль серверів */
// Створює EC2 інстанси для Jenkins контролера та серверів додатків.
module "jenkins-server" {
  source                        = "./modules/jenkins-server"
  instance_type                 = var.instance_type // Тип EC2 інстансу.
  public_subnet_ids             = module.networking.public_subnets_ids // ID публічних підмереж.
  jenkins_security_group_id     = module.security.jenkins_security_group_id // ID групи безпеки для Jenkins.
  jenkins_node_security_group_id = module.security.jenkins_node_security_group_id
  environment                   = var.environment
  jenkins_instance_profile_name = module.security.jenkins_instance_profile_name
  private_key_path              = module.security.private_key_file_path
  jenkins_key_pair_name         = module.security.jenkins_key_pair_name
  jenkins_node_instance_profile_name = module.security.jenkins_node_instance_profile_name
}

