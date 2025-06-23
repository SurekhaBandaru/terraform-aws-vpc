data "aws_availability_zones" "available" { #any meaningful string
  state = "available"
}

# output "av_zone" {
#   value = data.aws_availability_zones.available
# }

# fetch default vpc's info
data "aws_vpc" "default" { # default - vpc name
  default = true           # whether the given vpc is default or not
}


#fetch main/default route table
data "aws_route_table" "main" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "association.main"
    values = ["true"]
  }

}