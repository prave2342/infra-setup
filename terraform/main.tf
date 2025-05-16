resource "aws_vpc" "eks-vpc" {
    cidr_block  = var.vpc_cidr

}

resource "aws_internet_gateway" "gateway" {
    vpc_id = aws_vpc.eks-vpc.id
    depends_on = [
        aws_vpc.eks-vpc
    ]
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



resource "aws_subnet" "jumpbox-subnet" {
    count                   = length(var.jumpbox_subnet_cidrs)
    vpc_id                  = aws_vpc.eks-vpc.id
    cidr_block              = var.jumpbox_subnet_cidrs[count.index]
    availability_zone       = var.zones[count.index]
    map_public_ip_on_launch = true
    depends_on = [
        aws_vpc.eks-vpc
    ]
}

resource "aws_route_table" "public-rt" {
    vpc_id = aws_vpc.eks-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gateway.id
    }
    depends_on = [
        aws_vpc.eks-vpc
    ]
}

resource "aws_route_table_association" "jumpbox-rt" {
    count          = length(var.jumpbox_subnet_cidrs)
    subnet_id      = aws_subnet.jumpbox-subnet[count.index].id
    route_table_id = aws_route_table.public-rt.id
    depends_on = [
        aws_vpc.eks-vpc,
        aws_route_table.public-rt
    ]
}

resource "aws_eip" "nat-eip" {
    domain = true
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat-eip.id
    subnet_id     = aws_subnet.jumpbox-subnet[0].id
    depends_on    = [
        aws_internet_gateway.gateway,
        aws_eip.nat-eip,
        aws_subnet.jumpbox-subnet

    ]
}

resource "aws_route_table" "eks-rt" {
    vpc_id = aws_vpc.eks-vpc.id
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
    depends_on = [
        aws_nat_gateway.nat,
        aws_vpc.eks-vpc
    ]
}


resource "aws_route_table_association" "private-rta" {
  count          = length(var.subnet_cidrs)
  subnet_id      = aws_subnet.eks-subnet[count.index].id
  route_table_id = aws_route_table.eks-rt.id
      depends_on =[
        aws_route_table.eks-rt,
        aws_vpc.eks-vpc
    ]
}

resource "aws_security_group" "jumpbox-nsg" {
    name   = var.jumpbox_nsg_name
    vpc_id = aws_vpc.eks-vpc.id
    ingress {
        description = "Allow SSH from your local machine"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
    }
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

resource "aws_iam_role" "eks-node-role" {
    name = "${var.cluster_name}-eks-node-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "ec2.amazonaws.com"
                },
                Action = "sts:AssumeRole"
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

resource "aws_iam_role_policy_attachment" "node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_iam_role_policy_attachment" "cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_iam_role_policy_attachment" "eks-registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-role.name
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

resource "aws_eks_node_group" "eks_nodes" {
    cluster_name    = aws_eks_cluster.eks-cluster.name
    node_group_name = "${var.cluster_name}-node-group"
    node_role_arn   = aws_iam_role.eks-node-role.arn
    subnet_ids      = aws_subnet.eks-subnet[*].id
    scaling_config {
        desired_size = 1
        max_size     = 2
        min_size     = 1
    }
    instance_types = var.node_instance_types
    ami_type = var.node_ami_type
    depends_on = [
        aws_eks_cluster.eks-cluster,
        aws_iam_role_policy_attachment.node-policy,
        aws_iam_role_policy_attachment.cni-policy,
        aws_iam_role_policy_attachment.eks-registry,
        aws_nat_gateway.nat,
        aws_route_table.eks-rt,
        aws_route_table_association.private-rta
    ]
}

resource "aws_key_pair" "key" {
    key_name   = var.key_name
    public_key = var.pub_key
}

resource "aws_instance" "jumpbox" {
    ami             = var.ami
    instance_type   = var.instance_type
    subnet_id       = aws_subnet.eks-subnet[0].id
    key_name        = aws_key_pair.key.key_name
    security_groups = [aws_security_group.jumpbox-nsg.name]
    depends_on = [
        aws_subnet.eks-subnet,
        aws_key_pair.key
    ]
}

output "jumpbox_ip" {
    value = aws_instance.jumpbox.public_ip
}