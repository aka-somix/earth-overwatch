#!/bin/bash

# Define tag values
EC2_TAG_KEY="Name"
EC2_TAG_VALUE="your-ec2-instance-tag" # Replace with the tag value for EC2

API_TAG_KEY="Name"
API_TAG_VALUE="your-api-gateway-tag" # Replace with the tag value for API Gateway

STAGE_TAG_KEY="Stage"
STAGE_TAG_VALUE="your-stage-tag"     # Replace with the tag value for the API Gateway stage

# Define colors for pretty prints
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Print a separator
separator() {
    echo -e "${CYAN}----------------------------------------------------${RESET}"
}

# Function to get EC2 instance ID based on tag
get_ec2_instance_id() {
    separator
    echo -e "${YELLOW}Retrieving EC2 instance ID based on tag: ${EC2_TAG_KEY}=${EC2_TAG_VALUE}${RESET}"
    separator

    EC2_INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:$EC2_TAG_KEY,Values=$EC2_TAG_VALUE" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text)

    if [ -z "$EC2_INSTANCE_ID" ]; then
        echo -e "${RED}No EC2 instance found with tag: $EC2_TAG_KEY=$EC2_TAG_VALUE${RESET}"
        exit 1
    else
        echo -e "${GREEN}Found EC2 instance ID: $EC2_INSTANCE_ID${RESET}"
    fi
}

# Function to get API ID and Stage Name based on tags
get_api_id_and_stage_name() {
    separator
    echo -e "${YELLOW}Retrieving API Gateway ID and stage name based on tags${RESET}"
    separator

    # Retrieve the API ID
    API_ID=$(aws apigateway get-rest-apis \
        --query "items[?tags.$API_TAG_KEY=='$API_TAG_VALUE'].id | [0]" \
        --output text)

    if [ -z "$API_ID" ]; then
        echo -e "${RED}No API Gateway found with tag: $API_TAG_KEY=$API_TAG_VALUE${RESET}"
        exit 1
    else
        echo -e "${GREEN}Found API Gateway ID: $API_ID${RESET}"
    fi

    # Retrieve the Stage Name
    STAGE_NAME=$(aws apigateway get-stages --rest-api-id $API_ID \
        --query "item[?tags.$STAGE_TAG_KEY=='$STAGE_TAG_VALUE'].stageName | [0]" \
        --output text)

    if [ -z "$STAGE_NAME" ]; then
        echo -e "${RED}No Stage found with tag: $STAGE_TAG_KEY=$STAGE_TAG_VALUE${RESET}"
        exit 1
    else
        echo -e "${GREEN}Found Stage Name: $STAGE_NAME${RESET}"
    fi
}

# Function to stop EC2 instance
stop_ec2_instance() {
    separator
    echo -e "${YELLOW}Stopping EC2 instance: ${EC2_INSTANCE_ID}${RESET}"
    separator

    aws ec2 stop-instances --instance-ids $EC2_INSTANCE_ID

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully stopped EC2 instance: $EC2_INSTANCE_ID${RESET}"
    else
        echo -e "${RED}Failed to stop EC2 instance: $EC2_INSTANCE_ID${RESET}"
        exit 1
    fi
}

# Function to delete API Gateway stage
delete_api_gateway_stage() {
    separator
    echo -e "${YELLOW}Deleting stage: ${STAGE_NAME} from API Gateway: ${API_ID}${RESET}"
    separator

    aws apigateway delete-stage --rest-api-id $API_ID --stage-name $STAGE_NAME

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully deleted stage: $STAGE_NAME from API Gateway: $API_ID${RESET}"
    else
        echo -e "${RED}Failed to delete stage: $STAGE_NAME from API Gateway: $API_ID${RESET}"
        exit 1
    fi
}

# Main execution
separator
echo -e "${CYAN}Starting the script to manage AWS resources...${RESET}"
separator

get_ec2_instance_id
get_api_id_and_stage_name

stop_ec2_instance
delete_api_gateway_stage

separator
echo -e "${CYAN}All operations completed successfully!${RESET}"
separator
