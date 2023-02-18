terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}




resource "aws_vpc" "my_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tf-example"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-example"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.example.id
}

resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "default_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.example.id
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_security_group" "my_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "my_auth" {
  key_name   = "my_key"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_instance" "foo" {
  ami                    = "ami-0735c191cf914754d" # us-west-2
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id              = aws_subnet.my_subnet.id
  key_name               = aws_key_pair.my_auth.key_name
  user_data              = file("script.sh")

  /*provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "git version",
      "mkdir code",
      "cd code",
      "git clone git@github.com:edwgarcia/testnpm.git",
      "cd testnpm",
      "npm install",
      "npm start",
    ]
  }*/

}

output "aws_instance_public_dns" {
  value = aws_instance.foo.public_dns
}