#!/bin/bash
# Run this ONCE before the first `cdk deploy`.
# Creates the AWS Secrets Manager secret that all ECS tasks and the infra EC2 read from.
#
# Usage:
#   chmod +x infrastructure/scripts/create-secrets.sh
#   ./infrastructure/scripts/create-secrets.sh

set -e

# ── Edit these values before running ──────────────────────────────────────────
POSTGRES_USER="decp_user"
POSTGRES_PASSWORD="postgres"
MONGO_ROOT_USERNAME="admin"
MONGO_ROOT_PASSWORD="mongodb"
RABBITMQ_USER="guest"
RABBITMQ_PASSWORD="guest"
JWT_SECRET="change_me_very_long_secret_key_at_least_32_chars"

# MongoDB URIs (uses the values above — no need to edit these)
REGION=$(aws configure get region)
MONGODB_URI_POSTS="mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@\${infraHost}:27017/decp_posts?authSource=admin"
MONGODB_URI_MESSAGING="mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@\${infraHost}:27017/decp_messaging?authSource=admin"
MONGODB_URI_NOTIFICATIONS="mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@\${infraHost}:27017/decp_notifications?authSource=admin"
# ──────────────────────────────────────────────────────────────────────────────

SECRET_JSON=$(cat <<EOF
{
  "POSTGRES_USER": "${POSTGRES_USER}",
  "POSTGRES_PASSWORD": "${POSTGRES_PASSWORD}",
  "MONGO_ROOT_USERNAME": "${MONGO_ROOT_USERNAME}",
  "MONGO_ROOT_PASSWORD": "${MONGO_ROOT_PASSWORD}",
  "RABBITMQ_USER": "${RABBITMQ_USER}",
  "RABBITMQ_PASSWORD": "${RABBITMQ_PASSWORD}",
  "JWT_SECRET": "${JWT_SECRET}",
  "MONGODB_URI_POSTS": "mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@INFRA_HOST:27017/decp_posts?authSource=admin",
  "MONGODB_URI_MESSAGING": "mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@INFRA_HOST:27017/decp_messaging?authSource=admin",
  "MONGODB_URI_NOTIFICATIONS": "mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@INFRA_HOST:27017/decp_notifications?authSource=admin"
}
EOF
)

echo "Creating secret decp/app-secrets..."
aws secretsmanager create-secret \
  --name "decp/app-secrets" \
  --description "DECP platform credentials" \
  --secret-string "${SECRET_JSON}"

echo ""
echo "Done. Secret ARN:"
aws secretsmanager describe-secret --secret-id "decp/app-secrets" --query ARN --output text
echo ""
echo "NOTE: After cdk deploy, update the MONGODB_URI_* values to replace INFRA_HOST"
echo "with the actual private IP from the InfraInstance CloudFormation output:"
echo ""
echo "  aws secretsmanager update-secret --secret-id decp/app-secrets --secret-string '{...}'"
