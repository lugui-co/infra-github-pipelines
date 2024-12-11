#!/bin/bash

setup_lambda_environment() {
    local service_name=$1
    local project_name=$2
    local branch=$3
    local service_name_env_suffix=$4

    # Set default values
    : ${GO_TO_DIR:="."}
    : ${SERVICE_NAME:=${project_name}}
    
    if [ "${service_name_env_suffix}" == "true" ]; then
        SERVICE_NAME="${service_name}-${branch}"
    fi

    echo "Service name configured as: ${SERVICE_NAME}"
    return 0
}

get_ecr_registry() {
    local service_name=$1
    
    local registry_address=$(aws ecr describe-repositories | \
        grep repositoryUri | \
        awk '{print $2}' | \
        sed -e 's/\"\(.*\)\"\,/\1/' | \
        grep "^.*${service_name}$" | \
        head -n 1)

    if [ -z "${registry_address}" ]; then
        echo "Error: ECR registry not found for service ${service_name}"
        exit 1
    fi

    echo ${registry_address}
}

update_lambda_function() {
    local service_name=$1
    local image_uri=$2

    echo "Updating Lambda function..."
    aws lambda update-function-code \
        --function-name ${service_name} \
        --image-uri "${image_uri}"
} 