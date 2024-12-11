#!/bin/bash

build_and_push_docker_image() {
    local registry_address=$1
    local ci_job_token=$2
    local go_to_dir=$3
    
    local timestamp=$(date +%s)

    # Login to ECR
    aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | \
        docker login --username AWS --password-stdin ${registry_address}

    # Build and tag images
    cd ${go_to_dir}
    docker build -t "${registry_address}:latest" \
        --build-arg CI_JOB_TOKEN="${ci_job_token}" .
    docker image tag "${registry_address}:latest" "${registry_address}:${timestamp}"

    # Push images in parallel
    docker push ${registry_address}:${timestamp} &
    docker push ${registry_address}:latest &
    wait

    docker logout ${registry_address}
    
    echo ${timestamp}
} 