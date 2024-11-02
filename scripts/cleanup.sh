#!/bin/bash

# Define tag values
EC2_TAG_KEY="Name"
EC2_TAG_VALUE="scrnts-dev-bastion-bastionhost" # Replace with the tag value for EC2

TAG_KEY="project"
TAG_VALUE="scrnts"  # Replace with the tag value for API Gateway

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
        --query "items[?tags.$TAG_KEY=='$TAG_VALUE'].id" \
        --output text)

    if [ -z "$API_IDS" ]; then
        echo -e "${RED}No API Gateways found with tag: $TAG_KEY=$TAG_VALUE${RESET}"
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
            --query "item[?tags.$TAG_KEY=='$TAG_VALUE'].stageName" \
            --output text)

        if [ -z "$STAGE_NAMES" ]; then
            echo -e "${RED}No stages found with tag: $TAG_KEY=$TAG_VALUE for API Gateway $API_ID${RESET}"
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

# Function to get and stop SageMaker notebooks based on tag
delete_sagemaker_notebooks() {
    separator
    echo -e "${YELLOW}Retrieving SageMaker notebooks based on tag: ${TAG_KEY}=${TAG_VALUE}${RESET}"
    separator

    # List all notebook instances
    NOTEBOOK_INSTANCE_NAMES=$(aws sagemaker list-notebook-instances \
        --query "NotebookInstances[].NotebookInstanceName" \
        --output text)

    if [ -z "$NOTEBOOK_INSTANCE_NAMES" ]; then
        echo -e "${RED}No SageMaker notebooks found.${RESET}"
    else
        for NOTEBOOK_INSTANCE_NAME in $NOTEBOOK_INSTANCE_NAMES; do
            # Retrieve tags for each notebook instance
            TAGS=$(aws sagemaker list-tags --resource-arn $(aws sagemaker describe-notebook-instance --notebook-instance-name $NOTEBOOK_INSTANCE_NAME --query 'NotebookInstanceArn' --output text))
            # Check if the tag key and value are present
            TAG_MATCH=$(echo "$TAGS" | jq -r ".Tags[] | select(.Key==\"$TAG_KEY\" and .Value==\"$TAG_VALUE\")")

            if [ -n "$TAG_MATCH" ]; then
                echo -e "${YELLOW}Deleting SageMaker notebook: $NOTEBOOK_INSTANCE_NAME${RESET}"
                aws sagemaker stop-notebook-instance --notebook-instance-name $NOTEBOOK_INSTANCE_NAME > /dev/null
                aws sagemaker delete-notebook-instance --notebook-instance-name $NOTEBOOK_INSTANCE_NAME > /dev/null

                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}Successfully deleted SageMaker notebook: $NOTEBOOK_INSTANCE_NAME${RESET}"
                else
                    echo -e "${RED}Failed to delete SageMaker notebook: $NOTEBOOK_INSTANCE_NAME${RESET}"
                fi
            else
                echo -e "${CYAN}Notebook $NOTEBOOK_INSTANCE_NAME does not match the tag criteria.${RESET}"
            fi
        done
    fi
}



# Main execution
separator
echo -e "${CYAN}Starting the script to manage AWS resources...${RESET}"
separator

get_ec2_instance_ids
get_api_ids_and_stage_names

stop_ec2_instances
delete_api_gateway_stages
delete_sagemaker_notebooks

separator
echo -e "${CYAN}All operations completed successfully!${RESET}"
separator
