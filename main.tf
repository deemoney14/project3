provider "aws" {
    region = "us-west-1"
  
}

#vpc
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    
    tags = {
      Name = "main_vpc"
    }
  
}

#subnet
resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-west-1a"
    map_public_ip_on_launch = true

    tags = {
      Name = "public subnet"
    }

}

#igw
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id

    tags = {
      Name = "igw"
    }
  
}

#Route table
resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }

    tags = {
      Name = "routetable"
    }
}

#Route Table Assocaition
resource "aws_route_table_association" "public_route" {
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.rt.id
}
# # Create a key pair
resource "aws_key_pair" "my_key" {
     key_name = "my-key-pair"
     public_key = file("new-key.pem.pub")
  
 }
#WEB SERVER
resource "aws_instance" "web1" {
    ami = "ami-04fdea8e25817cd69"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    key_name = aws_key_pair.my_key.key_name

    user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    echo "Hello World" > /var/www/html/hello.txt
    systemctl start httpd
    systemctl enable httpd
EOF


    tags = {
      Name = "web_one"
    } 
}
output "instance_ip" {
    value = aws_instance.web1.public_ip
  
}
# SG
resource "aws_security_group" "web_sg" {
    name = "web_sg"
    description = "Allow SSH and http to my instance"
    vpc_id = aws_vpc.main.id 
}

resource "aws_security_group_rule" "ssh_rule" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.web_sg.id
  
}
resource "aws_security_group_rule" "http_rules" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.web_sg.id
  
}

resource "aws_security_group_rule" "out_rules" {
    type = "egress"
    to_port = 0
    from_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.web_sg.id
  
}
