#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="eu-west-1"                       
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

BUCKET="cloudguard-tfstate-${AWS_ACCOUNT_ID}"
TABLE="cloudguard-tflock"

aws s3api create-bucket \
    --bucket "${BUCKET}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}" \
    2>/dev/null || echo "Bucket ${BUCKET} already exists"

aws s3api put-bucket-versioning \
    --bucket "${BUCKET}" \
    --versioning-configuration Status=Enabled \
    --region "${AWS_REGION}"


aws dynamodb describe-table \
    --table-name "${TABLE}" \
    --region "${AWS_REGION}" >/dev/null 2>&1 || \
aws dynamodb create-table \
    --table-name "${TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}"

echo "Backend created in ${AWS_REGION}: s3://${BUCKET}, DynamoDB ${TABLE}"
