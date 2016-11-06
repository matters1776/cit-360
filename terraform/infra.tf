# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-6f48540b"
}


#provider block configures name provider (aws) - creates and manages resources

provider "aws" {
  access_key = ""
  secret_key = ""
  region = "us-west-2"
}


# create resource VPC gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}" 
  tags = {
    Name = "default_ig"
  }
}



# creates elastic IP to assign it to NAT gateway
resource "aws_eip" "tuto_eip" {
    vpc = true
    depends_on = ["aws_internet_gateway.gw"]
}


#create NAT gateway - enables instances in the private subnet to connect to the internet

resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.tuto_eip.id}"
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    depends_on = ["aws_internet_gateway.gw"]
}

#create public routing table - creates routes that determine where network traffic will be directed

resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}


# create private route table  and route to the internet
resource "aws_route_table" "private_route_table" {
    vpc_id = "${var.vpc_id}"
 
    tags {
        Name = "Private route table"
    }
}
 

 # creates private routing for the internet

resource "aws_route" "private_route" {
	route_table_id  = "${aws_route_table.private_route_table.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.nat.id}"
}



# create public subnet a

resource "aws_subnet" "public_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.0.0/24"
    availability_zone = "us-west-2a"
   
    tags {
        Name = "Public_Subnet_1"
    }
}

# public route for subnet a

resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}


#create second public subnet

resource "aws_subnet" "public_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.1.0/24"
    availability_zone = "us-west-2b"

    tags {
        Name = "Public_Subnet_2"
    }
}

#public route association for subnet b

resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_b.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}






#create third public subnet

resource "aws_subnet" "public_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.2.0/24"
    availability_zone = "us-west-2c"

    tags {
        Name = "Public_Subnet_3"
    }
}

#public route assocation for subnet c

resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_c.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}


# create private subnet a

resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "172.31.4.0/22"
  availability_zone = "us-west-2a"
  tags = {
  	Name =  "Private_Subnet_1"
  }
}

#create route assocication for private subnet a

resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}



# create private subnet b

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "172.31.8.0/22"
  availability_zone = "us-west-2b"
  tags = {
        Name =  "Private_Subnet_2"
  }
}

#create route association for private subnet b

resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}




#third private subnet c
resource "aws_subnet" "private_subnet_c" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "172.31.12.0/22"
  availability_zone = "us-west-2c"
  tags = {
        Name =  "Private_Subnet_3"
  }
}

# create route assocation for private subnet c

resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}


# create security group, allows acess from current public IP address to an instance on port 22  via SSH

resource "aws_security_group" "allow_all" {
  name = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
      from_port = 0
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


# create Bastion Instance EC2 - acts as a bridge to private instances via the internet 

resource "aws_instance" "bastion" {
  ami = "ami-b04e92d0"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  security_groups = ["${aws_security_group.allow_all.id}"]
  key_name = "cit360"
}