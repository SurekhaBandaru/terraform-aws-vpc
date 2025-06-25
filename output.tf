#added for testing 
output "vpc_id" {
  value = aws_vpc.main.id # get the vpc id from vpc declared in vpc.tf
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id #here * is all, we will get a list of subnet ids, here we created 2 public subnets
}


output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database[*].id
}
