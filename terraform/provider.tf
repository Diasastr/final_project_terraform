provider "aws" {
  region                  = var.region
  shared_credentials_files = ["C:\\Users\\streb\\.aws\\credentials"] #change to the location of your credentials
  profile                 = "default"
}

