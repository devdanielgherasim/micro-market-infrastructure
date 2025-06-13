#!/bin/bash

kubectl apply -f ./configs/production_issuer.yaml

CI_PROJECT_NAMESPACE="microservices1691717"
PUBLIC_IP_NAME=$(az network public-ip list --resource-group rg-$CI_PROJECT_NAMESPACE-dev-aks --query "[?contains(name, 'kubernetes-')].name" -o tsv)
az network public-ip update --resource-group rg-$CI_PROJECT_NAMESPACE-dev-aks --name $PUBLIC_IP_NAME --dns-name $CI_PROJECT_NAMESPACE