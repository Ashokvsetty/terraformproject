provider "aws" {
  region = "ap-south-1"
  access_key = "AKIATUMZDLBQCEZYPZ5X"
  secret_key = "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"
}

resource "aws_vpc" "app_vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    name= "app_vpc"
  }
}

resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "app_igw"
  }
}

resource "aws_route_table" "custom_rt" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "custom_rt"
  }
}

resource "aws_subnet" "public-subnet-AZ1" {
  cidr_block = "10.1.1.0/24"
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet-AZ1"
  }
}

resource "aws_subnet" "public-subnet-AZ2" {
  cidr_block = "10.1.2.0/24"
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = "ap-south-1b"
  tags = {
    Name = "public-subnet-AZ2"
  }
}

resource "aws_subnet" "public-subnet-AZ3" {
  cidr_block = "10.1.3.0/24"
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = "ap-south-1c"
  tags = {
    Name = "public-subnet-AZ3"
  }
}

resource "aws_subnet" "private-subnet-AZ1" {
  cidr_block = "10.1.4.0/24"
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private-subnet-AZ1"
  }
}

resource "aws_subnet" "private-subnet-AZ2" {
  cidr_block = "10.1.5.0/24"
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private-subnet-AZ2"
  }
}

resource "aws_subnet" "private-subnet-AZ3" {
  cidr_block = "10.1.6.0/24"
  vpc_id = aws_vpc.app_vpc.id
  availability_zone = "ap-south-1c"
  tags = {
    Name = "private-subnet-AZ3"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet-AZ1.id
  route_table_id = aws_route_table.custom_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public-subnet-AZ2.id
  route_table_id = aws_route_table.custom_rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.public-subnet-AZ3.id
  route_table_id = aws_route_table.custom_rt.id
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP"
  }
}


resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTPS"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["150.129.60.67/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow SSH"
  }
}

resource "aws_network_interface" "webserver-eni" {
  subnet_id = aws_subnet.public-subnet-AZ1.id
  private_ips = ["10.1.1.10"]
  security_groups = [
    aws_security_group.allow_https.id,
    aws_security_group.allow_http.id,
    aws_security_group.allow_ssh.id]
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webserver-eni.id
  associate_with_private_ip = "10.1.1.10"
  depends_on = [aws_internet_gateway.app_igw]
}

resource "aws_instance" "webserver-instance" {
  ami = "ami-04b1ddd35fd71475a"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.webserver-eni.id
  }
  user_data = file("install_apache.sh")
	tags = {
		Name = "WebServer"

	}

}

