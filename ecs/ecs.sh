#!/bin/sh

set -eo pipefail

export CI_COMMIT_BRANCH=${GITHUB_REF_NAME}

export CI_PROJECT_NAME=$(echo "${GITHUB_REPOSITORY}" | awk -F / '{print $2}')

apk add --no-cache aws-cli git

# BEGIN carregando chaves

mkdir ~/.aws
touch ~/.aws/credentials

aws ssm get-parameters --names "/cicd/${ACCOUNT_FAMILY}/credentials" --with-decryption --query "Parameters[0].Value" --output text > ~/.aws/credentials

if [ "$(cat ~/.aws/credentials)" == "null" ] && [ "$(cat ~/.aws/credentials)" == "None" ]; then
    echo "nao achei as credenciais da aws."

    echo "o ambiente esta configurado certo?"

    echo "verifique a variavel de ambiente ACCOUNT_FAMILY"

    exit 1
fi

export AWS_PROFILE=${CI_COMMIT_BRANCH}

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

export region_candidate=$(aws ssm get-parameters --names "/cicd/account/region/${CI_COMMIT_BRANCH}" --with-decryption --query "Parameters[0].Value" --output text)

if [ "${region_candidate}" != "null" ] && [ "${region_candidate}" != "None" ]; then
    export AWS_DEFAULT_REGION=${region_candidate}

else
    export region_candidate=$(aws ssm get-parameters --names "/cicd/account/region" --with-decryption --query "Parameters[0].Value" --output text)

    if [ "${region_candidate}" != "null" ] && [ "${region_candidate}" != "None" ]; then
        export AWS_DEFAULT_REGION=${region_candidate}
    fi
fi

# END carregando chaves

if [ -z "${SERVICE_NAME}" ]; then
    export SERVICE_NAME=${CI_PROJECT_NAME}
fi

export OLD_SERVICE_NAME=${SERVICE_NAME}

if [ -z "${POS_PEND}" ]; then
    export SERVICE_NAME=${SERVICE_NAME}-${CI_COMMIT_BRANCH}
else
    export SERVICE_NAME=${SERVICE_NAME}${POS_PEND}
fi

echo "service: ${SERVICE_NAME}"

if [ -z "${GO_TO_DIR}" ]; then
    export GO_TO_DIR="."
fi

export CLUSTER_NAME="cluster not found"

for i in $(aws ecs list-clusters --query 'clusterArns' --output text); do
    for service in $(aws ecs list-services --query 'serviceArns' --output text --cluster $i); do
        if [ $(echo "$service" | grep ${SERVICE_NAME}) ]; then
            CLUSTER_NAME=${i}
            echo "cluster: ${CLUSTER_NAME}"
            break
        fi
    done
done

export ECR_REGISTRY_ADDRESS=$(aws ecr describe-repositories | grep repositoryUri | awk '{print $2}' | sed -e 's/\"\(.*\)\"\,/\1/' | grep ${SERVICE_NAME})

echo "regisstry: ${ECR_REGISTRY_ADDRESS}"

aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY_ADDRESS}

export TIMESTAMP=$(date +%s)

cd ${GO_TO_DIR}

echo "${ENVIRONMENT}" >> .env.${CI_COMMIT_BRANCH}
echo "${ENVIRONMENT_TEST}" >> .env.test

export ARGUMENTS=""

for i in $(echo "${BUILD_ARGS}"); do
    export ARGUMENTS="${ARGUMENTS} --build-arg ${i}"
done

docker build -t "${ECR_REGISTRY_ADDRESS}:latest" --build-arg CI_JOB_TOKEN="${CI_JOB_TOKEN}"${ARGUMENTS} .

docker image tag "${ECR_REGISTRY_ADDRESS}:latest" "${ECR_REGISTRY_ADDRESS}:${TIMESTAMP}"

docker push ${ECR_REGISTRY_ADDRESS}:${TIMESTAMP} &
docker push ${ECR_REGISTRY_ADDRESS}:latest &

wait

docker logout $ECR_REGISTRY_ADDRESS

sleep 5

aws ecs update-service --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --force-new-deployment