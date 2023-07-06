## Introduction

Kubernetes is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. AWS (Amazon Web Services) is a cloud computing platform that provides a wide range of services and tools for building and deploying applications in the cloud. 

In this project, we will use Terraform to provision a Kubernetes cluster on AWS. Terraform is an open-source infrastructure as code tool that allows you to define and manage your infrastructure as code. Using Terraform, we can define our infrastructure in a single configuration file, which can be version controlled and shared with others. 

## Prerequisites

Before you begin, you will need the following:

- An AWS account
- Terraform installed on your machine
- Basic knowledge of Kubernetes and AWS

## Steps

The following are the steps we will follow to provision a Kubernetes cluster on AWS using Terraform:

1. Define the provider configuration for AWS.
2. Define the VPC configuration for the Kubernetes cluster.
3. Define the subnet configuration for the Kubernetes cluster.
4. Define the internet gateway configuration for the Kubernetes cluster.
5. Define the route table configuration for the Kubernetes cluster.
6. Define the security group configuration for the Kubernetes cluster.
7. Define the EC2 instance configuration for the Kubernetes master node.
8. Use user data to install Kubernetes on the master node.
9. Output the public IP address of the Kubernetes master node.

### 1. Define the provider configuration for AWS

The first step is to define the provider configuration for AWS. This tells Terraform which region to use and how to authenticate with AWS. 

```terraform
# Provider configuration
provider "aws" {
  region = "us-west-2"
}
```

In this example, we are using the `us-west-2` region. You can change this to any region supported by AWS.

### 2. Define the VPC configuration for the Kubernetes cluster

The next step is to define the VPC (Virtual Private Cloud) configuration for the Kubernetes cluster. A VPC is a virtual network in AWS that you can use to launch your resources. 

```terraform
# VPC configuration
resource "aws_vpc" "kubernetes_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "kubernetes-vpc"
  }
}
```

In this example, we are using the CIDR block `10.0.0.0/16` for the VPC. You can change this to any CIDR block that does not overlap with your existing networks.

### 3. Define the subnet configuration for the Kubernetes cluster

The next step is to define the subnet configuration for the Kubernetes cluster. A subnet is a range of IP addresses in your VPC. 

```terraform
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
```

In this example, we are using three subnets with CIDR blocks `10.0.1.0/24`, `10.0.2.0/24`, and `10.0.3.0/24`. You can change the number and size of the subnets based on your needs.

### 4. Define the internet gateway configuration for the Kubernetes cluster

The next step is to define the internet gateway configuration for the Kubernetes cluster. An internet gateway is a horizontally scaled, redundant, and highly available VPC component that allows communication between instances in your VPC and the internet. 

```terraform
# Internet gateway configuration
resource "aws_internet_gateway" "kubernetes_igw" {
  vpc_id = aws_vpc.kubernetes_vpc.id
  tags = {
    Name = "kubernetes-igw"
  }
}
```

In this example, we are creating a single internet gateway for the VPC.

### 5. Define the route table configuration for the Kubernetes cluster

The next step is to define the route table configuration for the Kubernetes cluster. A route table contains a set of rules, called routes, that are used to determine where network traffic is directed. 

```terraform
# Route table configuration
resource "aws_route_table" "kubernetes_route_table" {
  vpc_id = aws_vpc.kubernetes_vpc.id
  tags = {
    Name = "kubernetes-route-table"
  }
}

resource "aws_route" "internet_gateway_route" {
  route_table_id = aws_route_table.kubernetes_route_table.id
  destination_cidr_block= "0.0.0.0/0"
  gateway_id = aws_internet_gateway.kubernetes_igw.id
}
```

In this example, we are creating a single route table for the VPC and adding a default route via the internet gateway.

### 6. Define the security group configuration for the Kubernetes cluster

The next step is to define the security group configuration for the Kubernetes cluster. A security group acts as a virtual firewall for your instances to control inbound and outbound traffic. 

```terraform
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
```

In this example, we are creating a single security group for the VPC that allows all inbound traffic on all ports and allows all outbound traffic.

### 7. Define the EC2 instance configuration for the Kubernetes master node

The next step is to define the EC2 instance configuration for the Kubernetes master node. An EC2 instance is a virtual server in the cloud that you can use to run your applications. 

```terraform
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
```

In this example, we are creating a single EC2 instance with the AMI ID `ami-0c55b159cbfafe1f0` (Ubuntu Server 18.04 LTS), the instance type `t2.medium`, and the key pair `kubernetes-keypair`. We are also using user data to install Kubernetes on the instance.

### 8. Use user data to install Kubernetes on the master node

We are using user data to install Kubernetes on the master node. User data is a script that runs when the instance boots up for the first time. 

```terraform
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
```

In this example, we are using the default kubeconfig file located at ~/.kube/config. You can change this to the path of your own kubeconfig file.
### 9. Output the public IP address of the Kubernetes master node

The final step is to output the public IP address of the Kubernetes master node. This can be used to connect to the master node and manage the Kubernetes cluster. 

```terraform
# Output the Kubernetes master public IP address
output "kubernetes_master_public_ip" {
  value = aws_instance.kubernetes_master.public_ip
}
```

In this example, we are outputting the public IP address of the Kubernetes master node using the `public_ip` attribute of the `aws_instance` resource. 

## To Run 
Write this command in terminal:

```
./apply.sh
```

if you face an error try to write these :

```
chmod +x apply.sh
```
## Conclusion

In this project, we used Terraform to provision a Kubernetes cluster on AWS. We defined the infrastructure for the cluster in a single configuration file, which can be version controlled and shared with others. We used user data to install Kubernetes on the master node, and outputted the public IP address of the master node for connecting to and managing the cluster. This project is just a starting point for provisioning a Kubernetes cluster on AWS using Terraform, and you can customize it based on your needs.