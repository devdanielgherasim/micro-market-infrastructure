project_id = "i-binder-461513-v8"
region     = "europe-central2"
zone       = "europe-central2-a"

project_name     = "microservices1691715"
environment      = "prod"
credentials_file = "../i-binder-461513-v8-40884e000270.json"

labels = {
  managedby   = "terraform"
  environment = "production"
  project     = "microservices"
  owner       = "adriangherasim"
}

node_count    = 1
machine_type  = "e2-standard-2"
disk_size_gb  = 50
