@REM set GITLAB_ACCESS_TOKEN=glpat-eycasQQB2xzVrKR9h6Yf
@REM set TF_STATE_NAME=default
@REM terraform init -backend-config="address=https://gitlab.com/api/v4/projects/68748909/terraform/state/%TF_STATE_NAME%" -backend-config="lock_address=https://gitlab.com/api/v4/projects/68748909/terraform/state/%TF_STATE_NAME%/lock" -backend-config="unlock_address=https://gitlab.com/api/v4/projects/68748909/terraform/state/%TF_STATE_NAME%/lock" -backend-config="username=adriangherasim1" -backend-config="password=%GITLAB_ACCESS_TOKEN%" -backend-config="lock_method=POST" -backend-config="unlock_method=DELETE" -backend-config="retry_wait_min=5"

terraform init 
terraform plan --var-file=./tfvars_files/prod.tfvars --var client_id="88376f43-c3ee-4be1-bd05-20c20128b666" --var client_secret="did8Q~cYC_by1Hk7bxeI9gph7ztwJGTcVsAlGbxc" --var tenant_id="607d63ca-9f36-4ad8-9f71-8b3efc392eb1" --var subscription_id="fa77afbb-f924-48ff-9fa3-5cd94bf4cb57"

@echo.
@echo To apply the changes, run:
@echo terraform apply --var-file=./tfvars_files/prod.tfvars --var client_id="88376f43-c3ee-4be1-bd05-20c20128b666" --var client_secret="did8Q~cYC_by1Hk7bxeI9gph7ztwJGTcVsAlGbxc" --var tenant_id="607d63ca-9f36-4ad8-9f71-8b3efc392eb1" --var subscription_id="fa77afbb-f924-48ff-9fa3-5cd94bf4cb57"

@echo.
@echo To apply only the resource group:
@echo terraform apply --var-file=./tfvars_files/prod.tfvars --var client_id="88376f43-c3ee-4be1-bd05-20c20128b666" --var client_secret="did8Q~cYC_by1Hk7bxeI9gph7ztwJGTcVsAlGbxc" --var tenant_id="607d63ca-9f36-4ad8-9f71-8b3efc392eb1" --var subscription_id="fa77afbb-f924-48ff-9fa3-5cd94bf4cb57" --target=azurerm_resource_group.rg

@echo.
@echo To apply only the AKS cluster:
@echo terraform apply --var-file=./tfvars_files/prod.tfvars --var client_id="88376f43-c3ee-4be1-bd05-20c20128b666" --var client_secret="did8Q~cYC_by1Hk7bxeI9gph7ztwJGTcVsAlGbxc" --var tenant_id="607d63ca-9f36-4ad8-9f71-8b3efc392eb1" --var subscription_id="fa77afbb-f924-48ff-9fa3-5cd94bf4cb57" --target=azurerm_kubernetes_cluster.k8s

@echo.
@echo To apply only the NGINX Ingress Controller:
@echo terraform apply --var-file=./tfvars_files/prod.tfvars --var client_id="88376f43-c3ee-4be1-bd05-20c20128b666" --var client_secret="did8Q~cYC_by1Hk7bxeI9gph7ztwJGTcVsAlGbxc" --var tenant_id="607d63ca-9f36-4ad8-9f71-8b3efc392eb1" --var subscription_id="fa77afbb-f924-48ff-9fa3-5cd94bf4cb57" --target=helm_release.nginx_ingress