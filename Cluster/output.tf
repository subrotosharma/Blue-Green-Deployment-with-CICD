output "cluster_id" {
    value = aws_eks_cluster.DevOpsSubroto.id
  }
  
  output "node_group_id" {
    value = aws_eks_node_group.DevOpsSubroto.id
  }
  
  output "vpc_id" {
    value = aws_vpc.DevOpsSubroto_vpc.id
  }
  
  output "subnet_ids" {
    value = aws_subnet.DevOpsSubroto_subnet[*].id
  }

