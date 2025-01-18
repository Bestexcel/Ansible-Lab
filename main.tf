#Creating local name for my resource

locals {
  name = "pmo"
}



# Create a custom VPC called pmo-vpc

resource "aws_vpc" "pmo-vpc" {
  cidr_block       = var.vpccidr
  instance_tenancy = "default"

  tags = {
    Name = "${local.name}-pmo-vpc"
  }
}

# Public and private subnets

//public subnets called pmo-Sub-pub1 
resource "aws_subnet" "pmo-sub-pub" {
  vpc_id            = (aws_vpc.pmo-vpc.id)
  cidr_block        = var.pubsubcidr
  availability_zone = var.az1
  tags = {
    Name = "${local.name}-pmo-sub-pub"
  }
}

#pmo-sub-priv1
resource "aws_subnet" "pmo-sub-priv" {
  vpc_id            = (aws_vpc.pmo-vpc.id)
  cidr_block        = var.prisubcidr
  availability_zone = var.az2
  tags = {
    Name = "${local.name}-pmo-sub-priv"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "pmo-igw" {
  vpc_id = aws_vpc.pmo-vpc.id

  tags = {
    Name = "${local.name}-pmo-igw"
  }
}

# Create Route Table
resource "aws_route_table" "pmo-rt" {
  vpc_id = aws_vpc.pmo-vpc.id

  route {
    cidr_block = var.allcidr
    gateway_id = aws_internet_gateway.pmo-igw.id
  }

  tags = {
    Name = "${local.name}-pmo-rt"
  }
}

# Associate Public Route Table With Public Subnet
//creating route table asociation1
resource "aws_route_table_association" "pmo-rt-assoc1" {
  subnet_id      = aws_subnet.pmo-sub-pub.id
  route_table_id = aws_route_table.pmo-rt.id
}

//creating route table asociation2
resource "aws_route_table_association" "pmo-rt-assoc2" {
  subnet_id      = aws_subnet.pmo-sub-priv.id
  route_table_id = aws_route_table.pmo-rt.id
}






#Creating Ansible security group
resource "aws_security_group" "ansible-sg" {
  name        = "ansible-sg allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.pmo-vpc.id

  ingress {
    description = "Allow SSH access"
    from_port   = var.sshport
    to_port     = var.sshport
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allcidr]
  }

  tags = {
    Name = "ansible-sg"
  }
}


#Creating manage node security group
resource "aws_security_group" "m-node-sg" {
  name        = "m-node-sg allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.pmo-vpc.id

  ingress {
    description = "Allow SSH access"
    from_port   = var.sshport
    to_port     = var.sshport
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

  ingress {
    description = "Allow http aceess"
    from_port   = var.httpport
    to_port     = var.httpport
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allcidr]
  }

  tags = {
    Name = "ansible-sg"
  }
}



#Creating keypair
/*
Note: visit the Terraform registry on the browser and search for tls and select hashicorp/tls,
click on documentation and select Resouces and choose tls private key and copy it 
*/

//creating RSA private-key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

//creating private key locally
/*
 creating this local file called key enables the key to be stored locally 
specifying that the content of the local file should be the tls private key and
 when terraform provisions the resource the name it will be given will be pmo-key and 
 the permission on the file will be 600 which means only the user can write and read the file.
 */

resource "local_file" "key" {
 content = tls_private_key.key.private_key_pem
 filename = "pmo-key"
 file_permission = "600"
}

//creating and registering the public key in AWS
/*
this pass the content of the file to aws. Note: the public key is passed to aws console to enable ssh.
*/

resource "aws_key_pair" "key" {
       key_name = "pmo-pub-key"
    public_key = tls_private_key.key.public_key_openssh
}


#creating instance
//creating ansible server
resource "aws_instance" "ansible" {
  ami = var.ubuntu //ansible ubuntu ami
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.id
  vpc_security_group_ids = [ aws_security_group.ansible-sg.id ]
  subnet_id = aws_subnet.pmo-sub-pub.id
  associate_public_ip_address = true
  user_data = file("./userdata.sh")
  tags = {
    Name = "${local.name}-ansible"
  }
}

#rehat Instance
resource "aws_instance" "redhat" {
  ami = var.redhat //redhat ami
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.id
  vpc_security_group_ids = [ aws_security_group.m-node-sg.id ]
  subnet_id = aws_subnet.pmo-sub-pub.id
  associate_public_ip_address = true
    tags = {
    Name = "redhat"
  }
}

#Ubuntu Instance
resource "aws_instance" "ubuntu" {
  ami = var.ubuntu //ubuntu ami
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.id
  vpc_security_group_ids = [ aws_security_group.m-node-sg.id ]
  subnet_id = aws_subnet.pmo-sub-pub.id
  associate_public_ip_address = true
  tags = {
    Name = "ubuntu"
  }
}


