#!/bin/bash
# Builds all service Docker images and pushes them to ECR.
# Run this from the repo root after `cdk deploy`.
#
# Usage:
#   chmod +x infrastructure/scripts/push-images.sh
#   ./infrastructure/scripts/push-images.sh

set -e

REGION=$(aws configure get region)
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"

SERVICES=(
  "api-gateway"
  "auth-service"
  "user-service"
  "post-service"
  "job-service"
  "event-service"
  "research-service"
  "messaging-service"
  "notification-service"
  "analytics-service"
  "mentorship-service"
)

echo "=== Logging in to ECR ==="
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

echo ""

for SERVICE in "${SERVICES[@]}"; do
  ECR_URI="${REGISTRY}/decp/${SERVICE}"
  echo "=== Building ${SERVICE} ==="
  docker build \
    -t "${SERVICE}:latest" \
    -f "backend/${SERVICE}/Dockerfile" \
    backend/

  echo "--- Tagging ${SERVICE} ==="
  docker tag "${SERVICE}:latest" "${ECR_URI}:latest"

  echo "--- Pushing ${SERVICE} ==="
  docker push "${ECR_URI}:latest"

  echo ""
done

echo "All images pushed to ECR."
echo ""
echo "Next: force ECS services to redeploy with the new images:"
echo "  aws ecs update-service --cluster decp-cluster --service <name> --force-new-deployment"
echo ""
echo "Or redeploy all at once:"
for SERVICE in "${SERVICES[@]}"; do
  echo "  aws ecs update-service --cluster decp-cluster --service ${SERVICE} --force-new-deployment"
done
