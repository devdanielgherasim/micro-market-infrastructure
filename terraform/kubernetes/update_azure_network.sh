#!/bin/bash

#kubectl apply -f ./configs/production_issuer.yaml
#
#CI_PROJECT_NAMESPACE="microservices1691712"
#PUBLIC_IP_NAME=$(az network public-ip list --resource-group rg-$CI_PROJECT_NAMESPACE-dev-aks --query "[?contains(name, 'kubernetes-')].name" -o tsv)
#az network public-ip update --resource-group rg-$CI_PROJECT_NAMESPACE-dev-aks --name $PUBLIC_IP_NAME --dns-name $CI_PROJECT_NAMESPACE

kubectl apply -f ./configs/argocd_project.yaml
kubectl apply -f ./configs/argocd_application.yaml