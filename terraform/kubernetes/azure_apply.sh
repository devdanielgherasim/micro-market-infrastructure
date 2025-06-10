#!/bin/bash

terraform init -backend-config="config.azure.tfbackend"

terraform apply --var-file=./tfvars_files/dev.tfvars \
  --var cloud_provider="azure" \
  --var client_id="88376f43-c3ee-4be1-bd05-20c20128b666" \
  --var client_secret="YgW8Q~c1koEgr-cvHgSnkCieYtYA2Pr~MFB6dbDu" \
  --var tenant_id="607d63ca-9f36-4ad8-9f71-8b3efc392eb1" \
  --var subscription_id="fa77afbb-f924-48ff-9fa3-5cd94bf4cb57"

kubectl apply -f ./configs/production_issuer.yaml
kubectl apply -f ./configs/argocd_network_policies.yaml
kubectl apply -f ./configs/prometheus_recording_rules.yaml
kubectl apply -f ./configs/prometheus_alerting_rules.yaml
kubectl apply -f ./configs/argocd_project.yaml
kubectl apply -f ./configs/argocd_application.yaml

CI_PROJECT_NAMESPACE="microservices1691716"
PUBLIC_IP_NAME=$(az network public-ip list --resource-group rg-$CI_PROJECT_NAMESPACE-dev-aks --query "[?contains(name, 'kubernetes-')].name" -o tsv)
az network public-ip update --resource-group rg-$CI_PROJECT_NAMESPACE-dev-aks --name $PUBLIC_IP_NAME --dns-name $CI_PROJECT_NAMESPACE