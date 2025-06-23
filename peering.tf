resource "aws_vpc_peering_connection" "default" {
  #peer_owner_id = account id of target aws account - not required here as we are using peering in same account
  count       = var.is_peering_required ? 1 : 0 # this block will execute only if this is_peering_required is true
  peer_vpc_id = data.aws_vpc.default.id         # from data source
  vpc_id      = aws_vpc.main.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  auto_accept = true #accept peering if two vpc in same account, same region

  tags = merge(var.vpc_peering_tags,
    local.comman_tags,
    {
      Name = "${var.project}-${var.environment}-default"
  })
}

# create routes
#public route
resource "aws_route" "public_peering" {
  count                     = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id # here used count.index because we used # count in aws_vpc_peering_connection and this is getting iterated and created like aws_vpc_peering_connection.default[0]

}

resource "aws_route" "private_peering" {
  count                     = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}


resource "aws_route" "database_peering" {
  count                     = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

# we should add peering connection in default VPC main route table to

resource "aws_route" "default_peering" {
  count                     = var.is_peering_required ? 1 : 0
  route_table_id            = data.aws_route_table.main.id # default route table id from data source
  destination_cidr_block    = var.cidr_block               # vpc cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id

}