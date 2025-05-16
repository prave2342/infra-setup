resource "aws_vpc" "eks-vpc" {
    cidr_block  = var.vpc_cidr
}
resource "aws_subnet" "eks-subnet" {
    count                   = length(var.subnet_cidrs)
    vpc_id                  = aws_vpc.eks-vpc.id
    cidr_block              = var.subnet_cidrs[count.index]
    availability_zone       = var.zones[count.index]
    depends_on = [
        aws_vpc.eks-vpc
    ]
}
resource "aws_iam_role" "eks-cluster-role" {
    name               = "${var.cluster_name}-eks-cluster-role"
    assume_role_policy = jsonencode({
        Version        = "2012-10-17",
        Statement      = [
            {
                Action    = "sts:AssumeRole",
                Effect    = "Allow",
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            }
        ]
    })
}
resource "aws_iam_role_policy_attachment" "eks-policy-attach" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks-cluster-role.name
    depends_on = [
        aws_iam_role.eks-cluster-role
    ]
}
resource "aws_eks_cluster" "eks-cluster" {
    name     = var.cluster_name
    role_arn = aws_iam_role.eks-cluster-role.arn
    vpc_config {
        subnet_ids              = aws_subnet.eks-subnet[*].id
        endpoint_private_access = true
        endpoint_public_access  = false
    }
    depends_on = [
        aws_iam_role_policy_attachment.eks-policy-attach,
        aws_subnet.eks-subnet
    ]
}

resource "aws_key_pair" "key" {
    key_name   = var.key_name
    public_key = var.pub_key
}

resource "aws_instance" "jumpbox" {
    ami           = var.ami
    instance_type = var.instance_type
    subnet_id     = aws_subnet.eks-subnet[0].id
    key_name      = aws_key_pair.key
    depends_on = [
        aws_subnet.eks-subnet,
        aws_key_pair.key
    ]
}


