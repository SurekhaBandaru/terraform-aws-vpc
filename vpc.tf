resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  # enable_dns_support   = true, this is true by default

  enable_dns_hostnames = true #whether to have dns host name support


  tags = merge(
    var.vpc_tags, #if any new tags, gets included, if any comman tags overriden by our comman tags
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}"

    }
  )
}


resource "aws_internet_gateway" "main" { #any meaningful name
  vpc_id = aws_vpc.main.id               #associate with vpc

  tags = merge(
    var.igw_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}"
    }
  )
}

#subnet-name = roboshop-dev-public-us-east-1a
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs) # as we need to create two pub subnets
  vpc_id                  = aws_vpc.main.id                 #associate with vpc
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.az_names[count.index]
  map_public_ip_on_launch = true #assign public ip addresses to the launched instances
  tags = merge(
    var.public_subnet_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
    }
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  tags = merge(
    var.private_subnet_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
    }
  )
}


resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  tags = merge(
    var.database_subnet_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}-database-${local.az_names[count.index]}"
    }
  )
}

#elastic ip
resource "aws_eip" "nat" { # any name 
  domain = "vpc"
  tags = merge(
    var.eip_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}"
    }
  )
}

#nat gateway
resource "aws_nat_gateway" "roboshop" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # we need to add the nat gateway in public subnet that too us-east-1a, here it is available at zeroth index
  tags = merge(
    var.nat_gateway_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}"
    }
  )
  depends_on = [aws_internet_gateway.main] # here terraform is asking for internet gateway, usually terraform implicitly checks for dependencies, but in this case it is unable to. And IGW dependency is not mentioned in AWS as well (not asked when creating NAT gateway). As we are keeping this NAT gateway inside public subnet, this public subnet shoul also connect to the outer world (internet) through IGW only, so we had to add the depends_on IGW here.
}

# route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.public_route_table_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}-public"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.private_route_table_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}-private"
    }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.database_route_table_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}-database"
    }
  )
}


#create routes
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"                  #allow public
  gateway_id             = aws_internet_gateway.main.id # as traffic trough internet gateway for public subnet
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.roboshop.id #natgateway works for only outbound traffic not to the incoming traffic
}

resource "aws_route" "database" {
  route_table_id         = aws_route_table.database.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.roboshop.id
}

#route table association with subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}