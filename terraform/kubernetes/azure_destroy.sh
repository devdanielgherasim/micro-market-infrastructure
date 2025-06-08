#!/bin/bash

terraform init -backend-config="config.azure.tfbackend"

kubectl delete -f ./configs/argocd_network_policies.yaml
kubectl delete -f ./configs/argocd_application.yaml
kubectl delete -f ./configs/argocd_project.yaml

kubectl delete -f ./configs/prometheus_recording_rules.yaml
kubectl delete -f ./configs/prometheus_alerting_rules.yaml

terraform destroy --var-file=./tfvars_files/dev.tfvars \
  --var cloud_provider="azure" \
  --var client_id="88376f43-c3ee-4be1-bd05-20c20128b666" \
  --var client_secret="YgW8Q~c1koEgr-cvHgSnkCieYtYA2Pr~MFB6dbDu" \
  --var tenant_id="607d63ca-9f36-4ad8-9f71-8b3efc392eb1" \
  --var subscription_id="fa77afbb-f924-48ff-9fa3-5cd94bf4cb57"

# terraform force-unlock <LOCK_ID>
