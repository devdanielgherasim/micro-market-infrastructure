region                 = "us-east-1"
project_name           = "danielgherasim-microservices"
environment            = "dev"
eks_node_instance_type = "t3.small"
eks_node_min_count     = 1
eks_node_desired_count = 1
eks_node_max_count     = 2
eks_node_disk_size     = 30
az_count               = 2
single_nat_gateway     = true
api_allowed_cidrs      = ["0.0.0.0/0"]

tags = {
  ManagedBy   = "Terraform"
  Environment = "dev"
  Project     = "danielgherasim-microservices"
  Owner       = "adriangherasim"
  CostCenter  = "adriangherasim1@gmail.com"
}
