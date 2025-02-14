#!/bin/bash

# Colors for logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

# Parameters
BASTION_HOST_NAME="scrnts-dev-bastion-bastionhost"
SSH_KEY_PATH="~/.ssh/ec2_personal"
LOCAL_PORT=5432
AWS_REGION="eu-west-1"

# List available Aurora clusters
echo -e "${BLUE}🔍 Fetching available Aurora clusters...${NC}"
CLUSTERS=($(aws rds describe-db-clusters --region $AWS_REGION \
  --query "DBClusters[].DBClusterIdentifier" --output text))

if [ ${#CLUSTERS[@]} -eq 0 ]; then
  echo -e "${RED}❌ No Aurora clusters found. Exiting.${NC}"
  exit 1
fi

# Display cluster options
echo -e "${YELLOW}Available Aurora Clusters:${NC}"
for i in "${!CLUSTERS[@]}"; do
  echo -e "${GREEN}$((i+1))) ${CLUSTERS[i]}${NC}"
done

# Prompt user to select a cluster
read -p "Enter the number of the cluster you want to tunnel to: " CHOICE
AURORA_CLUSTER_NAME=${CLUSTERS[$((CHOICE-1))]}

if [ -z "$AURORA_CLUSTER_NAME" ]; then
  echo -e "${RED}❌ Invalid selection. Exiting.${NC}"
  exit 1
fi

# Retrieve RDS endpoint
echo -e "${BLUE}🔍 Fetching RDS endpoint for cluster: $AURORA_CLUSTER_NAME${NC}"
RDS_ENDPOINT=$(aws rds describe-db-clusters --region $AWS_REGION \
  --query "DBClusters[?DBClusterIdentifier=='$AURORA_CLUSTER_NAME'].Endpoint" \
  --output text)

if [ -z "$RDS_ENDPOINT" ]; then
  echo -e "${RED}❌ Error: Could not retrieve RDS endpoint. Exiting.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ RDS Endpoint: $RDS_ENDPOINT${NC}"

# Retrieve EC2 Instance ID
echo -e "${BLUE}🔍 Fetching EC2 instance ID for Name tag: $BASTION_HOST_NAME${NC}"
EC2_INSTANCE_ID=$(aws ec2 describe-instances --region $AWS_REGION \
  --filters "Name=tag:Name,Values=$BASTION_HOST_NAME" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text)

if [ -z "$EC2_INSTANCE_ID" ]; then
  echo -e "${RED}❌ Error: Could not retrieve EC2 instance ID. Exiting.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ EC2 Instance ID: $EC2_INSTANCE_ID${NC}"

# Establish SSH Tunnel
echo -e "${YELLOW}🚀 Establishing SSH tunnel...${NC}"
ssh -N -L $LOCAL_PORT:$RDS_ENDPOINT:5432 ec2-user@$EC2_INSTANCE_ID -i $SSH_KEY_PATH -vvv