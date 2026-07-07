region                          = "eu-central-1"
project_name                    = "danielgherasim-microservices"
environment                     = "staging"
eks_node_instance_type          = "t3.small"
eks_node_min_count              = 1
eks_node_desired_count          = 2
eks_node_max_count              = 3
eks_node_disk_size              = 30
az_count                        = 2
single_nat_gateway              = false
api_allowed_cidrs               = []
secrets_recovery_window_in_days = 7

tags = {
  ManagedBy   = "Terraform"
  Environment = "staging"
  Project     = "danielgherasim-microservices"
  Owner       = "adriangherasim"
  CostCenter  = "adriangherasim1@gmail.com"
}
