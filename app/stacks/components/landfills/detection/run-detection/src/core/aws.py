import boto3

sagemaker = boto3.client("sagemaker")
s3 = boto3.client("s3")
sqs = boto3.client("sqs")
