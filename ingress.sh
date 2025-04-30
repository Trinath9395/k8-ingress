#!/bin/bash

# Set environment variables
REGION_CODE="us-east-1"
CLUSTER_NAME="expense"
ACC_ID="658775564324"

# Step 1: Associate the OIDC provider with the EKS cluster
echo "Associating IAM OIDC provider with the EKS cluster..."
eksctl utils associate-iam-oidc-provider \
    --region $REGION_CODE \
    --cluster $CLUSTER_NAME \
    --approve

# Step 2: Download the IAM policy JSON file
echo "Downloading the IAM policy..."
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.12.0/docs/install/iam_policy.json

# Step 3: Create IAM Policy
echo "Creating IAM policy AWSLoadBalancerControllerIAMPolicy..."
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json

# Step 4: Create IAM service account and attach the policy
echo "Creating IAM service account for the AWS Load Balancer Controller..."
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::$ACC_ID:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region $REGION_CODE \
    --approve

# Step 5: Add the EKS chart repo to Helm
echo "Adding EKS Helm chart repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Step 6: Install the AWS Load Balancer Controller using Helm
echo "Installing AWS Load Balancer Controller..."
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

# Step 7: Verification
echo "Verifying the deployment..."
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
