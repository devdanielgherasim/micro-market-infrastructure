#!/bin/bash

kubectl apply -f ../../issuer.yaml

CI_PROJECT_NAMESPACE="microservices1691715"
PUBLIC_IP_NAME=$(az network public-ip list --resource-group rg-microservices1691715-dev-aks --query "[?contains(name, 'kubernetes-')].name" -o tsv)
az network public-ip update --resource-group rg-$CI_PROJECT_NAMESPACE-dev-aks --name $PUBLIC_IP_NAME --dns-name $CI_PROJECT_NAMESPACE
