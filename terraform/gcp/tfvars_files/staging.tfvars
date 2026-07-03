project_id = "i-binder-461513-v8"
region     = "europe-central2"
zone       = "europe-central2-a"

project_name = "danielgherasim-microservices"
environment  = "staging"

labels = {
  managedby   = "terraform"
  environment = "staging"
  project     = "microservices"
  owner       = "adriangherasim"
}

node_count   = 1
machine_type = "e2-standard-2"
disk_size_gb = 50
