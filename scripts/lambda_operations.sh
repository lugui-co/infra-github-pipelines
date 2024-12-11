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

build_python_package() {
    local dir=$1
    
    cd $dir
    
    echo "Building Python package..."
    touch ./requirements.txt
    pip install --no-cache --target ./package -r ./requirements.txt

    echo "Creating deployment package..."
    touch .lambdaignore
    7z a -mx=9 -mfb=64 \
        -xr'@.lambdaignore' \
        -xr'!.lambdaignore' \
        -xr'!.*' \
        -xr'!*.md' \
        -xr'!*git*' \
        -xr'!*.txt' \
        -xr'!*.h' \
        -xr'!*.hpp' \
        -xr'!*.c' \
        -xr'!*.cpp' \
        -xr'!*.zip' \
        -xr'!*.rar' \
        -xr'!*.sh' \
        -xr'!*__pycache__*' \
        -xr'!*.pyc' \
        -xr'!*.pyo' \
        -xr'!function_policy.json' \
        -xr'!function_policy_arguments.json' \
        -r main.zip .
}

update_python_lambda() {
    local service_name=$1
    
    echo "Updating Python Lambda function..."
    aws lambda update-function-code \
        --function-name ${service_name} \
        --zip-file fileb://main.zip
} 