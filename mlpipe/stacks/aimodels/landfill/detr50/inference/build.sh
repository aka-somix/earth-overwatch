#!/bin/bash

# Colors for separators
CYAN='\033[0;36m'
RESET='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'

# Function to print a separator
separator() {
    echo -e "${CYAN}---------------------------------------------------------------------------------${RESET}"
}
separator_err() {
    echo -e "${RED}---------------------------------------------------------------------------------${RESET}"
}
separator_ok() {
    echo -e "${GREEN}---------------------------------------------------------------------------------${RESET}"
}

# Ensure script is run with required arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <s3-bucket-name> <version> <folder>"
    exit 1
fi

BUCKET_NAME=$1
VERSION=$2
S3_DEST_FOLDER=$3
CHECKPOINT=$4

S3_MODEL_TENSOR_CHECKPOINT_URL= "s3://${BUCKET_NAME}/checkpoints/detr50/landfills-detection/test/model.safetensors"
S3_MODEL_CONFIG_CHECKPOINT_URL= "s3://${BUCKET_NAME}/checkpoints/detr50/landfills-detection/test/config.json"

separator
echo "Using S3 Bucket Name: $BUCKET_NAME"
echo "Using Version: $VERSION"
echo "Using Folder: $S3_DEST_FOLDER"
separator

# Create the model directory and save inference script and YOLOv8 weights
separator
echo "Creating Build"
separator

mkdir -p .build/code
mkdir -p .build/checkpoint
aws s3 cp ${S3_MODEL_TENSOR_CHECKPOINT_URL} .build/checkpoint/model.safetensors
aws s3 cp ${S3_MODEL_CONFIG_CHECKPOINT_URL} .build/checkpoint/config.json
cp code/inference.py .build/code/
cp code/requirements.txt .build/code/

separator
echo "Compressing Build to TAR"
separator
mkdir -p .out
tar -czvf .out/model.tar.gz -C .build .

# Upload to S3
separator
echo "Shipping to S3"
separator
aws s3 cp .out/model.tar.gz s3://$BUCKET_NAME/models/$S3_DEST_FOLDER/$VERSION/model.tar.gz

if [ $? -eq 0 ]; then
    separator_ok
    echo "Successfully uploaded to s3://$BUCKET_NAME/models/$S3_DEST_FOLDER/$VERSION/model.tar.gz"
    separator_ok
else
    separator_err
    echo "Error: Failed to upload to S3"
    separator_err
    exit 1
fi
