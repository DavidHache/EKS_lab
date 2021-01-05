provider "aws" {
    profile = "default"
    region = "us-east-1"
}

resource "aws_ec2_transit_gateway" "corp_transit_gw" {
  description = "Corp Transit Gateway"
  tags = {
    Environment = "EKS LAB",
    Name = "Corp transit gateway"
  }
}


#VPC's

resource "aws_vpc" "eks_private" {
  cidr_block = "192.168.0.0/23"
  
    tags = {
    Environment = "EKS LAB",
    Name = "EKS Private"
  }
}


resource "aws_vpc" "corp_private" {
  cidr_block = "10.0.0.0/27"
  
    tags = {
    Environment = "EKS LAB",
    Name = "Corp Private"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.eks_private.id
  cidr_block = "192.168.0.0/24"

  tags = {
    Environment = "EKS LAB",
    Name = "private_a"
  }
}

resource "aws_subnet" "corp_a" {
  vpc_id     = aws_vpc.corp_private.id
  cidr_block = "10.0.0.0/28"

  tags = {
    Environment = "EKS LAB",
    Name = "corp_a"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.corp_private.id

  tags = {
    Environment = "EKS LAB",
    Name = "corp_gw"
  }
  depends_on = [aws_vpc.corp_private]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "eks_private_corp_transit" {
  subnet_ids         = [aws_subnet.private_a.id]
  transit_gateway_id = aws_ec2_transit_gateway.corp_transit_gw.id
  vpc_id             = aws_vpc.eks_private.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "corp_private_corp_transit" {
  subnet_ids         = [aws_subnet.corp_a.id]
  transit_gateway_id = aws_ec2_transit_gateway.corp_transit_gw.id
  vpc_id             = aws_vpc.corp_private.id
}


resource "aws_eip" "nat_ip" {
  vpc = true
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.corp_a.id

  tags = {
    Environment = "EKS_LAB",
    Name = "corp_nat_gw"
  }
}

