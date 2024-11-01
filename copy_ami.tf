#east 1
provider "aws" {
    region = "us-east-1"
    alias = "east"

}
# copying into east 1
resource "aws_ami_copy" "copy" {
    provider = aws.east
  name              = "terraform-copy"
  description       = "A copy of ami from us-west-1 to us east-1"
  source_ami_id     = "ami-04fdea8e25817cd69"
  source_ami_region = "us-west-1"

  tags = {
    Name = "it works"
  }
}

#Default VPC in east 1
data "aws_vpc" "default" {
    provider = aws.east
    default = true 
 
}
#Default Subnet
data "aws_subnet" "default_subnets" {
    provider = aws.east

    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default.id]
    }

    filter {
      name = "availability-zone"
      values = ["us-east-1a"]
    }

}

# Create a key pair
resource "aws_key_pair" "east-key" {
     key_name = "east-key-pair"
     provider = aws.east
     public_key = file("east-key.pem.pub")
}

# launch the template
resource "aws_instance" "east1-webserver" {
    provider = aws.east
    ami = aws_ami_copy.copy.id
    instance_type = "t2.micro"
    associate_public_ip_address = true
    subnet_id = data.aws_subnet.default_subnets.id
    key_name = aws_key_pair.east-key.key_name
    vpc_security_group_ids = [aws_default_security_group.east-1sg.id]

    user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    echo "Hello World from East-1" > /var/www/html/hello.txt
    systemctl start httpd
    systemctl enable httpd
  EOF

    tags = {
      Name = "webserver-east1"
    }
  
}

output "instance_ip_east" {
  value = aws_instance.east1-webserver
  
}

# Security Group
resource "aws_default_security_group" "east-1sg" {
    vpc_id = data.aws_vpc.default.id
    provider = aws.east

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "web_sg"
  }
}