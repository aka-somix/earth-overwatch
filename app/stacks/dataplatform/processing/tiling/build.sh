#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -r <AWS_REGION> -e <ECR_REGISTRY> -n <REPOSITORY_NAME> -t <IMAGE_TAG>"
    echo "  -r AWS region (e.g., eu-west-1)"
    echo "  -e ECR registry URI (e.g., 772012299168.dkr.ecr.eu-west-1.amazonaws.com)"
    echo "  -n Repository name"
    echo "  -t Image tag (e.g., latest)"
    exit 1
}

# Parse command-line arguments
while getopts "r:e:n:t:" opt; do
    case $opt in
        r) AWS_REGION="$OPTARG" ;;
        e) ECR_REGISTRY="$OPTARG" ;;
        n) REPOSITORY_NAME="$OPTARG" ;;
        t) IMAGE_TAG="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all required arguments are provided
if [ -z "$AWS_REGION" ] || [ -z "$ECR_REGISTRY" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$IMAGE_TAG" ]; then
    usage
fi

# Authenticate Docker to the AWS ECR registry
echo "Authenticating Docker to AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
if [ $? -ne 0 ]; then
    echo "Error: Failed to authenticate Docker with AWS ECR"
    exit 1
fi

# Build the Docker image
echo "Building the Docker image..."
docker build -t $REPOSITORY_NAME . --platform=linux/x86_64
if [ $? -ne 0 ]; then
    echo "Error: Docker image build failed"
    exit 1
fi

# Tag the Docker image for the ECR repository
ECR_IMAGE_URI="$ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG"
echo "Tagging the Docker image as $ECR_IMAGE_URI..."
docker tag $REPOSITORY_NAME:latest $ECR_IMAGE_URI
if [ $? -ne 0 ]; then
    echo "Error: Failed to tag Docker image"
    exit 1
fi

# Push the Docker image to AWS ECR
echo "Pushing the Docker image to AWS ECR..."
docker push $ECR_IMAGE_URI
if [ $? -ne 0 ]; then
    echo "Error: Failed to push Docker image to AWS ECR"
    exit 1
fi

echo "Docker image successfully pushed to $ECR_IMAGE_URI"
