# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-6f48540b"
}


variable "db_password"
  { 
}

resource "aws_vpc" "main" {
 cidr_block = "172.31.0.0/16"
}


#provider block configures name provider (aws) - creates and manages resources

provider "aws" {
  access_key = "AKIAJCMP2KG377QRPRMA"
  secret_key = "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"
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


resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_c.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}


resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "172.31.4.0/22"
  availability_zone = "us-west-2a"
  tags = {
    Name =  "Private_Subnet_1"
  }
}



resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}


resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "172.31.8.0/22"
  availability_zone = "us-west-2b"
  tags = {
        Name =  "Private_Subnet_2"
  }
}



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


resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}


# create security group, allows acess from current public IP address to an instance on port 22  via SSH

resource "aws_security_group" "allow_all" {
  vpc_id = "${var.vpc_id}"
  name = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["130.166.220.254/32","172.31.0.0/16"]
  }


}

# create Bastion Instance EC2 - acts as a bridge to private instances via the internet 
#bastion host helps secure AWS infastructure

resource "aws_instance" "bastion" {
  ami = "ami-b04e92d0"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  associate_public_ip_address = true
  security_groups = ["${aws_security_group.allow_all.id}"]
  key_name = "cit360"
}



# Security Group for DB, per assignment 3,
resource "aws_security_group" "security_group_db" {
  
  name = "security_group_db"
  description = "Allow all inbound traffic"
  vpc_id = "${var.vpc_id}"
  ingress {
      from_port = 0
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

# new security group ingress rule port 80 and 22
resource "aws_security_group" "ingress_rule_port_80_22" {
 
  name = "ingress_rule_port_80_22"
  vpc_id = "${var.vpc_id}"
  ingress {
      from_port = 80
      to_port = 80
      protocol = "TCP"
      cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["${aws_vpc.main.cidr_block}"]

}


}

# new security group for the ELP port 80 from anywhere
resource "aws_security_group" "elb_security_group" {

  name = "elb_security_group"
  vpc_id = "${var.vpc_id}"
  ingress {
      from_port = 80
      to_port = 80
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]

}
}

#DB subnet Group
resource "aws_db_subnet_group" "default" {
    name = "main"
    subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
    tags {
        Name = "My DB subnet group"
    }

}


#relations Database Service RDS instance

#a DB instance is an isolated database environment in the cloud which can contain multiple user-created databases

resource "aws_db_instance" "my-db" {
  allocated_storage    = 5
  identifier           = "myinstance"
  engine               = "mariadb"
  engine_version       = "10.0.24"
  storage_type         = "gp2"
  instance_class       = "db.t2.micro"
  multi_az             =  false
  publicly_accessible  =  false
  name                 = "mydb"
  username             = "root"
  password             = "#{var.db_password}"
  db_subnet_group_name = "main"
  parameter_group_name = "default.mariadb10.0"
  tags {
      Name                   = "my-db"

}

}

#second EC2 instance, this instance will be placed in us-2west-2b private subnet

resource "aws_instance" "EC2_2" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  associate_public_ip_address = false
  security_groups = ["${aws_security_group.allow_all.id}"]
  key_name = "cit360"

  tags {
    Name = "webserver-b"
    Service = "Curriculum"


}
}

#third EC2 instance, this instance will be placed in us-2west-2c private subnet


resource "aws_instance" "EC2_3" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  associate_public_ip_address = false
  security_groups = ["${aws_security_group.allow_all.id}"]
  key_name = "cit360"

  tags {
    Name = "webserver-c"
    Service = "curriculum"

}

}







# Create a new load balancer
resource "aws_elb" "bar" {
  name = "foobar-terraform-elb"
  subnets  = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]
  security_groups = ["${aws_security_group.elb_security_group.id}"] 
  
listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.EC2_2.id}", "${aws_instance.EC2_3.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 60

  tags {
    Name = "terraform-elb"

}

} 
