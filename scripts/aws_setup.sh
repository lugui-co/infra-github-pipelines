#!/bin/bash

setup_aws_credentials() {
    local account_family=$1
    local branch=$2

    mkdir -p ~/.aws
    touch ~/.aws/credentials

    # Load AWS credentials from SSM
    aws ssm get-parameters \
        --names "/cicd/${account_family}/credentials" \
        --with-decryption \
        --query "Parameters[0].Value" \
        --output text > ~/.aws/credentials

    if [ "$(cat ~/.aws/credentials)" == "null" ] || [ "$(cat ~/.aws/credentials)" == "None" ]; then
        echo "Error: AWS credentials not found."
        echo "Please verify the ACCOUNT_FAMILY environment variable."
        exit 1
    fi

    export AWS_PROFILE=${branch}
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY

    # Set AWS region
    set_aws_region "${branch}"
}

set_aws_region() {
    local branch=$1
    
    # Try branch-specific region first
    local region=$(aws ssm get-parameters \
        --names "/cicd/account/region/${branch}" \
        --with-decryption \
        --query "Parameters[0].Value" \
        --output text)

    # Fall back to default region if branch-specific not found
    if [ "${region}" == "null" ] || [ "${region}" == "None" ]; then
        region=$(aws ssm get-parameters \
            --names "/cicd/account/region" \
            --with-decryption \
            --query "Parameters[0].Value" \
            --output text)
    fi

    if [ "${region}" != "null" ] && [ "${region}" != "None" ]; then
        export AWS_DEFAULT_REGION=${region}
    fi
} 