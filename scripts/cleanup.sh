#!/bin/bash

# Define tag values
EC2_TAG_KEY="Name"
EC2_TAG_VALUE="scrnts-dev-bastion-bastionhost" # Replace with the tag value for EC2

API_TAG_KEY="project"
API_TAG_VALUE="scrnts"  # Replace with the tag value for API Gateway

STAGE_TAG_KEY="project"
STAGE_TAG_VALUE="scrnts"      # Replace with the tag value for the API Gateway stage

# Define colors for pretty prints
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m's

# Print a separator
separator() {
    echo -e "${CYAN}----------------------------------------------------${RESET}"
}

# Function to get EC2 instance IDs based on tag
get_ec2_instance_ids() {
    separator
    echo -e "${YELLOW}Retrieving EC2 instance IDs based on tag: ${EC2_TAG_KEY}=${EC2_TAG_VALUE}${RESET}"
    separator

    EC2_INSTANCE_IDS=$(aws ec2 describe-instances \
        --filters "Name=tag:$EC2_TAG_KEY,Values=$EC2_TAG_VALUE" "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text)

    if [ -z "$EC2_INSTANCE_IDS" ]; then
        echo -e "${RED}No EC2 instances found with tag: $EC2_TAG_KEY=$EC2_TAG_VALUE${RESET}"
        exit 1
    else
        echo -e "${GREEN}Found EC2 instance IDs: $EC2_INSTANCE_IDS${RESET}"
    fi
}

# Function to get API IDs and Stage Names based on tags
get_api_ids_and_stage_names() {
    separator
    echo -e "${YELLOW}Retrieving API Gateway IDs and stage names based on tags${RESET}"
    separator

    # Retrieve the API IDs
    API_IDS=$(aws apigateway get-rest-apis \
        --query "items[?tags.$API_TAG_KEY=='$API_TAG_VALUE'].id" \
        --output text)

    if [ -z "$API_IDS" ]; then
        echo -e "${RED}No API Gateways found with tag: $API_TAG_KEY=$API_TAG_VALUE${RESET}"
        exit 1
    else
        echo -e "${GREEN}Found API Gateway IDs: $API_IDS${RESET}"
    fi
}

# Function to stop EC2 instances
stop_ec2_instances() {
    separator
    echo -e "${YELLOW}Stopping EC2 instances: ${EC2_INSTANCE_IDS}${RESET}"
    separator

    for EC2_INSTANCE_ID in $EC2_INSTANCE_IDS; do
        aws ec2 stop-instances --instance-ids $EC2_INSTANCE_ID > /dev/null

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully stopped EC2 instance: $EC2_INSTANCE_ID${RESET}"
        else
            echo -e "${RED}Failed to stop EC2 instance: $EC2_INSTANCE_ID${RESET}"
        fi
    done
}

# Function to delete API Gateway stages for each API
delete_api_gateway_stages() {
    for API_ID in $API_IDS; do
        separator
        echo -e "${YELLOW}Processing API Gateway: $API_ID${RESET}"
        separator

        # Retrieve stages for the current API ID
        STAGE_NAMES=$(aws apigateway get-stages --rest-api-id $API_ID \
            --query "item[?tags.$STAGE_TAG_KEY=='$STAGE_TAG_VALUE'].stageName" \
            --output text)

        if [ -z "$STAGE_NAMES" ]; then
            echo -e "${RED}No stages found with tag: $STAGE_TAG_KEY=$STAGE_TAG_VALUE for API Gateway $API_ID${RESET}"
        else
            echo -e "${GREEN}Found stages for API Gateway $API_ID: $STAGE_NAMES${RESET}"
            for STAGE_NAME in $STAGE_NAMES; do
                separator
                echo -e "${YELLOW}Deleting stage: $STAGE_NAME from API Gateway: $API_ID${RESET}"
                separator

                aws apigateway delete-stage --rest-api-id $API_ID --stage-name $STAGE_NAME > /dev/null

                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}Successfully deleted stage: $STAGE_NAME from API Gateway: $API_ID${RESET}"
                else
                    echo -e "${RED}Failed to delete stage: $STAGE_NAME from API Gateway: $API_ID${RESET}"
                fi
            done
        fi
    done
}

# Main execution
separator
echo -e "${CYAN}Starting the script to manage AWS resources...${RESET}"
separator

get_ec2_instance_ids
get_api_ids_and_stage_names

stop_ec2_instances
delete_api_gateway_stages

separator
echo -e "${CYAN}All operations completed successfully!${RESET}"
separator
