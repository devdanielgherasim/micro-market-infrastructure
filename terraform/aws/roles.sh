#!/usr/bin/env bash

set -euo pipefail

#AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
#
#aws eks create-access-entry \
#  --cluster-name eks-danielgherasim-microservices-dev \
#  --principal-arn arn:aws:iam::${AWS_ACCOUNT_ID}:user/daniel-admin \
#  --region eu-central-1
#
#  # Grant cluster-admin level access
#aws eks associate-access-policy \
#  --cluster-name eks-danielgherasim-microservices-dev \
#  --principal-arn arn:aws:iam::${AWS_ACCOUNT_ID}:user/daniel-admin \
#  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
#  --access-scope type=cluster \
#  --region eu-central-1

aws iam attach-user-policy \
    --user-name daniel-admin \
    --policy-arn arn:aws:iam::aws:policy/job-function/Billing