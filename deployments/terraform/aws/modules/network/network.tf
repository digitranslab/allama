# Fetch available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  available_azs = data.aws_availability_zones.available.names
  az_count      = min(var.az_count, length(local.available_azs))
  azs           = slice(local.available_azs, 0, local.az_count)
}

# VPC
resource "aws_vpc" "allama" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "allama-vpc"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.allama.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                        = "allama-public-${local.azs[count.index]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id                  = aws_vpc.allama.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                                        = "allama-private-${local.azs[count.index]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "allama" {
  vpc_id = aws_vpc.allama.id

  tags = merge(var.tags, {
    Name = "allama-igw"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = local.az_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "allama-nat-eip-${local.azs[count.index]}"
  })

  depends_on = [aws_internet_gateway.allama]
}

# NAT Gateways
resource "aws_nat_gateway" "allama" {
  count = local.az_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "allama-nat-${local.azs[count.index]}"
  })

  depends_on = [aws_internet_gateway.allama]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.allama.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.allama.id
  }

  tags = merge(var.tags, {
    Name = "allama-public-rt"
  })
}

# Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for HA)
resource "aws_route_table" "private" {
  count = local.az_count

  vpc_id = aws_vpc.allama.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.allama[count.index].id
  }

  tags = merge(var.tags, {
    Name = "allama-private-rt-${local.azs[count.index]}"
  })
}

# Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
