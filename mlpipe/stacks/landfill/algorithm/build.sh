#!/bin/bash

YOLO_CHECKPOINT_URL=https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11m.pt

# Create the model directory and save inference script and YOLOv8 weights
echo "----------------------------------------"
echo "Creating Build"
echo "----------------------------------------"
mkdir .build
mkdir .build/code
mkdir .out
wget ${YOLO_CHECKPOINT_URL}
mv yolo11m.pt .build/
cp code/inference.py .build/code/
cp code/requirements.txt .build/code/

echo "----------------------------------------"
echo "Compressing Build to TAR"
echo "----------------------------------------"
tar -czvf .out/model.tar.gz -C .build .

# Upload to s3
echo "----------------------------------------"
echo "Shipping to S3"
echo "----------------------------------------"
aws s3 cp .out/model.tar.gz s3://scrnts-dev-dataplat-ai-models-eu-west-1-772012299168/models/genericyolo/model-v$(date +%Y%m%d).tar.gz
