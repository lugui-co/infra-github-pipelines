#!/bin/bash

setup_terraform_environment() {
    local branch=$1
    local account_family=$2

    # Preparar arquivo tfvars
    mkdir -p ./environments
    touch ./environments/${branch}.tfvars
    aws ssm get-parameters --names "/cicd/account/tfvars" --with-decryption \
        --query "Parameters[0].Value" --output text >> ./environments/${branch}.tfvars
}

initialize_terraform() {
    local branch=$1
    local region=$2

    terraform init -force-copy -input=false \
        -backend-config bucket="lugui-terraform-states-${branch}" \
        -backend-config dynamodb_table="lugui-terraform-states-${branch}" \
        -backend-config shared_credentials_file=~/.aws/credentials \
        -backend-config profile=${branch} \
        -backend-config region=${region}

    # Select or create workspace
    terraform workspace select ${branch} || terraform workspace new ${branch}
}

run_terraform_plan() {
    local branch=$1
    terraform plan -out=tfplan.json -input=false -var-file ./environments/${branch}.tfvars
}

run_terraform_apply() {
    local plan_file=$1
    
    # Ajustar permissões do arquivo de plano
    sudo chown -R $(whoami):$(whoami) ${plan_file}
    sudo chmod -R 777 ${plan_file}

    terraform apply -auto-approve -input=false ${plan_file}
} 