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
variable "key_name"{
    type = string
}
variable "pub_key"{
    type = string
}
variable "ami" {
    type = string
}
variable "instance_type" {
    type = string
}
variable "node_instance_types" {
    type = list(string)
}
variable "node_ami_type" {
    type = string
}
variable "jumpbox_subnet_cidrs" {
    type = list(string)
}
variable "jumpbox_nsg_name" {
    type = string
}
variable "my_ip" {
    type = string
}