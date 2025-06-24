output "vpc_id" {
  value = aws_vpc.main.id # get the vpc id from vpc declared in vpc.tf
}