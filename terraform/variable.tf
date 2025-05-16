variable "region" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "subnet_cidrs" {
  type = list(string)
}
variable "access_key"{
    type = string
}
variable "secret_key"{
    type = string
}
variable "zones"{
    type = list(string)
}