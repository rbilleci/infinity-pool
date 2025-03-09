# Steps
## 1. Get simplistic version working, end-to-end.
## 2. Add Multi-AZ support
## 3. Networking improvements (VPN, Private Link, CDN, etc...)

# OSX Install

### Install Docker Desktop
https://docs.docker.com/desktop/setup/install/mac-install/

### Install Brew

### Update Brew
    
    brew update

### Install Terraform, Terragrunt, Kubectl, and Helm

    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    brew install terragrunt
    brew install kubectl
    brew install helm


# Install the AWS CLI

    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Commands

    aws configure
    export AWS_REGION=eu-west-1
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Building and dunning the docker containers locally
    
    
    docker build -t gateway .
    docker run -p 8080:80 gateway

    docker build -t backend .
    docker run -p 8081:80 backend


# Deploying
    terragrunt apply

# Build and Push the Docker images for the services

    export REPOURI=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/infinity-pool

    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REPOURI}

    cd app/backend
    docker buildx build --platform linux/amd64,linux/arm64 -t backend .
    docker tag backend:latest ${REPOURI}:backend-latest
    docker push ${REPOURI}:backend-latest
    cd ../..

    cd app/gateway
    docker buildx build --platform linux/amd64,linux/arm64 -t gateway .
    docker tag gateway:latest ${REPOURI}:gateway-latest
    docker push ${REPOURI}:gateway-latest
    cd ../..

# Deploying the service

    aws eks update-kubeconfig --region eu-west-1 --name infinity-pool-eks
    helm upgrade --install infinity-pool ./helm --set aws.region=$(aws configure get region) --set aws.accountId=$(aws sts get-caller-identity --query Account --output text)

# Cleaning up
    terraform deploy


