"""
Lambda for uploading datasets to Amazon EFS
"""
import os
import boto3

# EFS configurations
efs_mount_path = "/mnt/datasets"

s3 = boto3.client('s3')

def handler(event, _ctx):
    # Validate Input
    assert "dataset_folder" in event

    # Manage S3
    if "bucket" in event:
        s3_bucket = event["bucket"]
        s3_folder = event["dataset_folder"]
    else:
        return {
            'statusCode': 501,
            'body': "Not Implemented. Currently this service only Supports S3 calls. Please provide both bucket and dataset folder in event."
        }

    # List objects in the S3 folder
    response = s3.list_objects_v2(Bucket=s3_bucket, Prefix=s3_folder)

    if 'Contents' not in response:
        return {
            'statusCode': 404,
            'body': f'No objects found in S3 bucket {s3_bucket} with prefix {s3_folder}'
        }

    # Ensure the EFS destination folder exists
    efs_destination = os.path.join(efs_mount_path, s3_folder)
    os.makedirs(efs_destination, exist_ok=True)

    # Copy each object from S3 to EFS
    for obj in response['Contents']:
        file_key = obj['Key']
        file_name = os.path.basename(file_key)
        
        if file_name:  # Ignore S3 'folder' objects
            efs_file_path = os.path.join(efs_destination, file_name)
            print(f"📦 Now Transfering file: {file_name} to {efs_file_path}")
            s3.download_file(s3_bucket, file_key, efs_file_path)

    return {
        'statusCode': 200,
        'body': f'Successfully copied {len(response["Contents"])} objects from S3 to EFS'
    }
