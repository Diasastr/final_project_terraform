#! /bin/bash
exec > >(tee /var/log/user-data.log|logger) 2>&1
echo "Starting user data script execution"

# Update the system
dnf update -y

# Set hostname for the Jenkins agent
hostnamectl set-hostname jenkins-agent

# Install necessary packages
dnf install -y aws-cli git java-11-amazon-corretto docker

# Retrieve Jenkins credentials from SSM
JENKINS_USERNAME=$(aws ssm get-parameter --name "/jenkins/credentials/username" --query "Parameter.Value" --output text)
JENKINS_PASSWORD=$(aws ssm get-parameter --name "/jenkins/credentials/password" --with-decryption --query "Parameter.Value" --output text)

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Ensure the Jenkins user exists before attempting to add it to the Docker group
if ! id -u jenkins &>/dev/null; then
    sudo useradd -m jenkins
    echo "Jenkins user created."
else
    echo "Jenkins user already exists."
fi

# Add Jenkins and ec2-user (or your specific agent's running user) to the Docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker ec2-user

# Set up the Jenkins agent's workspace directory
sudo mkdir -p /home/jenkins/agent
sudo chown jenkins:jenkins /home/jenkins/agent
sudo chown ec2-user:ec2-user /home/jenkins/agent
chmod +x /home/jenkins/agent/jdk/bin/java

cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
sed -i 's/^ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/127.0.0.1:2376 -H unix:\/\/\/var\/run\/docker.sock/g' /lib/systemd/system/docker.service
systemctl daemon-reload


# Install Docker Compose
DockerComposeVersion="1.29.2" # Adjust to the desired version
curl -L "https://github.com/docker/compose/releases/download/${DockerComposeVersion}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Ansible
dnf install -y ansible

# Install pip & boto3
dnf install -y python3-pip
pip3 install boto3

# Install Terraform
wget "https://releases.hashicorp.com/terraform/${TerraformVersion}/terraform_${TerraformVersion}_linux_amd64.zip"
unzip terraform_${TerraformVersion}_linux_amd64.zip -d /usr/local/bin/
rm -f terraform_${TerraformVersion}_linux_amd64.zip

# Construct JENKINS_AUTH from retrieved username and password
JENKINS_AUTH="$${JENKINS_USERNAME}:$${JENKINS_PASSWORD}"

docker run -d \
    --net host \
    -e JENKINS_URL=http://"${controller_ip}":8080 \
    -e JENKINS_AUTH="$${JENKINS_AUTH}" \
    -v /home/jenkins/agent:/var/jenkins_home \
    -v /run/docker.sock:/run/docker.sock \
    -v /usr/bin/docker:/usr/bin/docker \
    simenduev/jenkins-auto-slave
