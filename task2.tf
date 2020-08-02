provider "aws" {
  region = "ap-south-1"
  profile = "rithwik"
}

#VPC
resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "myvpc"
  }
}

#Public_Subnet
resource "aws_subnet" "mysubnet-1a" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "mysubnet-1a"
  }
}

#Private_Subnet
resource "aws_subnet" "mysubnet-1b" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "mysubnet-1b"
  }
}


#Internet_Gateway
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "myigw"
  }
}

#Route_Table
resource "aws_route_table" "rt-1a" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
  
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "rt-1a"
  }
}

#Subnet_Association
resource "aws_route_table_association" "assoc-1a" {
  subnet_id      = aws_subnet.mysubnet-1a.id
  route_table_id = aws_route_table.rt-1a.id

  depends_on = [
    aws_subnet.mysubnet-1a,
  ]
}

#Wordpress_SG
resource "aws_security_group" "wordpress-sg" {
  name        = "wordpress-sg"
  description = "allows ssh and http"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "To allow ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "for port 80"
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

  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "wordpress-sg"
  }
}



#SQL_SG
resource "aws_security_group" "sql-sg" {
  name        = "sql-sg"
  description = "allows wordpress SG"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "connection to sql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.wordpress-sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  depends_on = [
    aws_vpc.myvpc,
    aws_security_group.wordpress-sg,
  ]

  tags = {
    Name = "sql-sg"
  }
}


#Wordpress_Instance

resource "aws_instance" wordpress {
  ami = "ami-7e257211"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet-1a.id
  key_name = "sshkey"
  vpc_security_group_ids = [aws_security_group.wordpress-sg.id]

  depends_on = [
    aws_subnet.mysubnet-1a,
    aws_security_group.wordpress-sg,
  ]

  tags = {
    Name = "wordpress"
  }
}


#SQL_Instance

resource "aws_instance" sql {
  ami = "ami-76166b19"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet-1b.id
  key_name = "sshkey"
  vpc_security_group_ids = [aws_security_group.sql-sg.id]

  depends_on = [
    aws_subnet.mysubnet-1b,
    aws_security_group.sql-sg,
  ]

  tags = {
    Name = "sql"
  }
}


