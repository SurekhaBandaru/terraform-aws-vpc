# VPC Module
This module is developed for joindevops company, projects inside joindevops follows this to create the VPC.

## Input
* project (Required) - Users should specify a project name

* environment (Required) - Users should specify an environment eg: dev, prod, stg, test etc.,

* cidr_block (Optional) - Users no need to specify cidr_block. Default one is "10.0.0.0/16"

## Outputs

* vpc_id - Exports VPC id created.
* public_subnet_ids - List of public subnet ids


