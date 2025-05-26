resource "null_resource" "jenkins_gitops_vm" {
  provisioner "local-exec" {
    command = <<EOT
multipass exec jenkins-gitops-vm -- bash -c "
  set -e
  echo '🔧 Updating packages...'
  sudo apt update
  echo '☕ Installing Jenkins...'
  sudo apt install -y openjdk-17-jdk curl gnupg unzip
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
  echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  sudo apt update
  sudo apt install -y jenkins
  sudo systemctl enable jenkins
  sudo systemctl start jenkins
  echo '✅ Jenkins installed:'
  systemctl status jenkins --no-pager | grep Active
  echo '🐳 Installing Docker...'
  sudo apt install -y docker.io
  sudo systemctl enable docker
  sudo systemctl start docker
  echo '✅ Docker version:'
  docker --version
  echo '☁️ Installing AWS CLI...'
  curl \"https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip\" -o \"awscliv2.zip\"
  unzip awscliv2.zip
  sudo ./aws/install
  echo '✅ AWS CLI version:'
  aws --version
  echo '📦 Installing kubectl...'
  curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl\"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  echo '✅ kubectl version:'
  kubectl version --client
  echo '⚙️ Installing eksctl...'
  curl --location \"https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_arm64.tar.gz\" | tar xz
  sudo mv eksctl /usr/local/bin
  echo '✅ eksctl version:'
  eksctl version
  echo '🛠️ Installing Terraform...'
  curl -fsSL \"https://releases.hashicorp.com/terraform/1.12.1/terraform_1.12.1_linux_arm64.zip\" -o terraform.zip
  unzip terraform.zip
  sudo mv terraform /usr/local/bin/
  echo '✅ Terraform version:'
  terraform -version
  echo '✅ All tools installed successfully!'
"
EOT
  }
}