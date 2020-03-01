variable "region" {
  default = "us-east-1"
}
variable "AmiLinux" {
  type = "map"
  default = {
    us-east-1 = "ami-b63769a1" # Virginia
  }
  description = "have only added one region"
}

variable "default_resource_group" {
  description = "Default value to be used in resources' Group tag."
  default     = "ssm-ansible"
}

variable "default_created_by" {
  description = "Default value to be used in resources' CreatedBy tag."
  default     = "terraform"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "web_server_port" {
default = 80
}
