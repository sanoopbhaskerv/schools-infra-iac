#!/bin/bash
set -e

# Configuration
BUCKET_NAME="schools-terraform-state-$(date +%s)" # Adding timestamp to ensure uniqueness
TABLE_NAME="schools-terraform-locks"
REGION="ap-south-1"

echo "Creating S3 Bucket: $BUCKET_NAME..."
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION

echo "Enabling Versioning..."
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

echo "Creating DynamoDB Table: $TABLE_NAME..."
# Check if table exists
if aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION >/dev/null 2>&1; then
    echo "Table $TABLE_NAME already exists."
else
    aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
        --region $REGION
fi

echo ""
echo "✅ Backend infrastructure created."
echo "Bucket: $BUCKET_NAME"
echo "Table:  $TABLE_NAME"
echo ""
echo "⚠️  IMPORTANT: Update your main.tf with the new bucket name: $BUCKET_NAME"
