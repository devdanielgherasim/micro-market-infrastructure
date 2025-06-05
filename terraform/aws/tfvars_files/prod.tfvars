region                 = "us-east-1"
project_name           = "microservices1691715"
environment            = "prod"
eks_node_instance_type = "t3.medium"
eks_node_count         = 3
eks_node_disk_size     = 50
subnet_count           = 2

tags = {
  ManagedBy   = "Terraform"
  Environment = "Production"
  Project     = "Microservices"
  Owner       = "adriangherasim"
  CostCenter  = "adriangherasim1@gmail.com"
}
