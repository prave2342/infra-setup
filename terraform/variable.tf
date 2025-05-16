variable "region" {
  type = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
 # default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type = string
  #default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "access_key"{
    type = string
}

variable "secret_key"{
    type = string
}
