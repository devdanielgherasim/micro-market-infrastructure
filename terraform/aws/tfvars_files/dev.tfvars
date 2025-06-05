region                 = "us-east-1"
project_name           = "microservices1691715"
environment            = "dev"
eks_node_instance_type = "t3.small"
eks_node_count         = 1
eks_node_disk_size     = 30
subnet_count           = 2

tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Project     = "Microservices"
  Owner       = "adriangherasim"
  CostCenter  = "adriangherasim1@gmail.com"
}
