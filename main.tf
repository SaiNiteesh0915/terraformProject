//Start of code here


//Credentials provided
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA2YGMIFLCUD2YQDFX"
  secret_key = "lNwL0F/cmKCVWljKKsn6s0YnK6ijguRM/Yr4RPPf"
}

resource "aws_vpc" "Project-1-VPC1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Sample_VPC"
  }
}

resource "aws_internet_gateway" "Project-1-GW1" {
  vpc_id = aws_vpc.Project-1-VPC1.id

  tags = {
    Name = "Sample_GW"
  }
}

resource "aws_route_table" "Project-1-RT1" {
  vpc_id = aws_vpc.Project-1-VPC1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Project-1-GW1.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.Project-1-GW1.id
  }

  tags = {
    Name = "Sample_RT"
  }
}

resource "aws_subnet" "Project_1-Subnet1" {
  vpc_id     = aws_vpc.Project-1-VPC1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Sample_Subnet"
  }
}

resource "aws_route_table_association" "Project_1-RTASSN" {
  subnet_id      = aws_subnet.Project_1-Subnet1.id
  route_table_id = aws_route_table.Project-1-RT1.id
}

resource "aws_security_group" "Project_1-SG" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.Project-1-VPC1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    //ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    //ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    //ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "Project_1-NetInt" {
  subnet_id       = aws_subnet.Project_1-Subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.Project_1-SG.id]

}

resource "aws_eip" "Project_1-EIP" {
  vpc                       = true
  network_interface         = aws_network_interface.Project_1-NetInt.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.Project-1-GW1]
}

resource "aws_instance" "Project_1-Instance1" {
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.Project_1-NetInt.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo Your very first web server > /var/www/html/index.html'
                EOF

  tags = {
    Name = "Terraform Test WebServer"
  }

}

//End of infrastruce deployment code here
