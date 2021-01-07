
provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}


# Networking.

#----------------------------
# VPC

resource "aws_vpc" "default" {
  cidr_block           = var.cidr_block_default
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = "EKS LAB",
    Name        = "Default"
  }
}

resource "aws_vpc" "eks" {
  cidr_block           = var.cidr_block_eks
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = "EKS LAB",
    Name        = "EKS Private"
  }
}



#----------------------------
# Internet GW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id
  tags = {
    Environment = "EKS LAB",
    Name        = "default_gw"
  }
  depends_on = [aws_vpc.default]
}

#----------------------------
# Subnets



resource "aws_subnet" "default_public" {
  count             = length(var.public_subnet_cidr_blocks_default)
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet_cidr_blocks_default[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Environment = "EKS LAB",
    Name        = "default_public_${count.index}"
  }
}

resource "aws_subnet" "default_private" {
  count             = length(var.private_subnet_cidr_blocks_default)
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.private_subnet_cidr_blocks_default[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Environment = "EKS LAB",
    Name        = "default_private_${count.index}"
  }
}

resource "aws_subnet" "eks" {
  count             = length(var.private_subnet_cidr_blocks_eks)
  vpc_id            = aws_vpc.eks.id
  cidr_block        = var.private_subnet_cidr_blocks_eks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Environment = "EKS LAB",
    Name        = "eks_a_${count.index}"
  }
}

#----------------------------
# Routing and Nat

resource "aws_eip" "nat_ip" {
  count = length(var.public_subnet_cidr_blocks_default)
  vpc   = true
  tags = {
    Environment = "EKS LAB"
    Name        = "Default Nat GW_${count.index}"
  }
}


resource "aws_nat_gateway" "default" {
  count         = length(var.public_subnet_cidr_blocks_default)
  allocation_id = aws_eip.nat_ip[count.index].id
  subnet_id     = aws_subnet.default_public[count.index].id
  depends_on    = [aws_internet_gateway.gw]
  tags = {
    Environment = "EKS_LAB",
    Name        = "Default Nat GW_${count.index}"
  }
}

resource "aws_route" "default_public" {
  route_table_id         = aws_vpc.default.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

}



resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidr_blocks_default)
  vpc_id = aws_vpc.default.id
  tags = {
    Environment = "EKS_LAB",
    Name        = "Default VPC Private Subnet Route ${count.index}"
  }
}

resource "aws_route" "default_private" {
  count                  = length(var.private_subnet_cidr_blocks_default)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr_blocks_default)
  subnet_id      = aws_subnet.default_private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


#----------------------------
# Transit gateways

resource "aws_ec2_transit_gateway" "default" {
  description = "Default Transit Gateway"
  tags = {
    Environment = "EKS LAB",
    Name        = "Default transit gateway"
  }
}


resource "aws_ec2_transit_gateway_vpc_attachment" "eks" {
  subnet_ids         = [for i in aws_subnet.eks : i.id]
  transit_gateway_id = aws_ec2_transit_gateway.default.id
  vpc_id             = aws_vpc.eks.id
  tags = {
    Environment = "EKS LAB"
    Name        = "Eks Attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "default_private" {
  subnet_ids         = [for i in aws_subnet.default_private : i.id]
  transit_gateway_id = aws_ec2_transit_gateway.default.id
  vpc_id             = aws_vpc.default.id
  tags = {
    Environment = "EKS LAB"
    Name        = "Default Private Attachment"
  }
}

resource "aws_ec2_transit_gateway_route" "default" {
  destination_cidr_block        = "0.0.0.0/0"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.default_private.id
  # transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.default_private.id}"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.default.association_default_route_table_id
  # transit_gateway_route_table_id = "${aws_ec2_transit_gateway.default.association_default_route_table_id}"

}

resource "aws_default_route_table" "eks_vpc" {
  default_route_table_id = aws_vpc.eks.default_route_table_id
  tags = {
    Environment = "EKS_LAB",
    Name        = "EKS VPC Main Route Table"
  }
}

resource "aws_route" "eks" {
  route_table_id         = aws_default_route_table.eks_vpc.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.default.id
  depends_on             = [aws_ec2_transit_gateway.default]

}

resource "aws_default_route_table" "default_vpc" {
  default_route_table_id = aws_vpc.default.default_route_table_id
  tags = {
    Environment = "EKS_LAB",
    Name        = "Default VPC Main Route Table"
  }
}

resource "aws_route" "default_to_eks" {
  route_table_id         = aws_default_route_table.default_vpc.id
  destination_cidr_block = var.cidr_block_eks
  transit_gateway_id     = aws_ec2_transit_gateway.default.id

}







#----------------------------
# Default VPC Security groups

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.default.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol    = -1
    cidr_blocks = [var.cidr_block_eks]
    from_port   = 0
    to_port     = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "EKS LAB"
    Name        = "Default VPC SG"
  }


}

resource "aws_default_security_group" "eks" {
  vpc_id = aws_vpc.eks.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol    = -1
    cidr_blocks = [var.cidr_block_default]
    from_port   = 0
    to_port     = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "EKS LAB"
    Name        = "EKS VPC SG"
  }
}

#----------------------------
# EKS Cluster

data "aws_eks_cluster" "cluster" {
  name = module.eks-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks-cluster.cluster_id
}


module "eks-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version
  subnets         = [for i in aws_subnet.eks : i.id]
  vpc_id          = aws_vpc.eks.id

  worker_groups = [
    {
      instance_type = "m4.large"
      asg_max_size  = 5
    }
  ]
}