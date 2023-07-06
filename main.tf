# Provider configuration
provider "aws" {
  region = "us-west-2"
}

# VPC configuration
resource "aws_vpc" "kubernetes_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "kubernetes-vpc"
  }
}

# Subnet configuration
resource "aws_subnet" "kubernetes_subnet" {
  count = 3
  cidr_block = "10.0.${count.index + 1}.0/24"
  availability_zone = "us-west-2a"
  vpc_id = aws_vpc.kubernetes_vpc.id
  tags = {
    Name = "kubernetes-subnet-${count.index + 1}"
  }
}

# Internet gateway configuration
resource "aws_internet_gateway" "kubernetes_igw" {
  vpc_id = aws_vpc.kubernetes_vpc.id
  tags = {
    Name = "kubernetes-igw"
  }
}

# Route table configuration
resource "aws_route_table" "kubernetes_route_table" {
  vpc_id = aws_vpc.kubernetes_vpc.id
  tags = {
    Name = "kubernetes-route-table"
  }
}

resource "aws_route" "internet_gateway_route" {
  route_table_id = aws_route_table.kubernetes_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.kubernetes_igw.id
}

# Security group configuration
resource "aws_security_group" "kubernetes_security_group" {
  name_prefix = "kubernetes-"
  vpc_id = aws_vpc.kubernetes_vpc.id

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance configuration
resource "aws_instance" "kubernetes_master" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.medium"
  count = 1
  subnet_id = aws_subnet.kubernetes_subnet.0.id
  vpc_security_group_ids = [aws_security_group.kubernetes_security_group.id]
  key_name = "kubernetes-keypair"
  tags = {
    Name = "kubernetes-master"
  }

  # User data for installing Kubernetes
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apt-transport-https curl
              curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
              cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
              deb https://apt.kubernetes.io/ kubernetes-xenial main
              EOF
              sudo apt-get update
              sudo apt-get install -y kubelet kubeadm kubectl
              sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans=<MASTER_PUBLIC_IP>
              mkdir -p $HOME/.kube
              sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
              sudo chown $(id -u):$(id -g) $HOME/.kube/config
              kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
              EOF
}

# Output
output "kubernetes_master_public_ip" {
  value = aws_instance.kubernetes_master.0.public_ip
}