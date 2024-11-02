"""
Script for uploading the dataset from roboflow to S3
"""

import os
import sys
from roboflow import Roboflow
from dotenv import load_dotenv
import subprocess


load_dotenv()  # take environment variables from .env.

VERSION = 2
ROBOFLOW_API_KEY = os.getenv("ROBOFLOW_API_KEY")
ROBOFLOW_PROJECT = os.getenv("ROBOFLOW_PROJECT")
S3_DATASET_PATH = os.getenv(
    "S3_DATASET_PATH"
)  # <- Path like: s3://bucket/path/to/dataset/
LOCAL_DATASET_PATH = f"./.local_dataset/v{VERSION}/"
#
# STEP 1: Download Dataset version from ROBOFLOW
#
print(f"⬇️ Downloading Dataset {ROBOFLOW_PROJECT} V{VERSION} from ROBOFLOW")
print("---")
try:
    rf = Roboflow(api_key=ROBOFLOW_API_KEY)
    project = rf.workspace("personals").project(ROBOFLOW_PROJECT)
    dataset = project.version(VERSION).download("coco", location=LOCAL_DATASET_PATH)
except Exception as e:
    print("Error downloading dataset from Roboflow:", e)
    exit(1)
#
# STEP 2: Uploading Dataset to S3
#
print(f"⬆️ Uploading Dataset to S3 at path {S3_DATASET_PATH}")
print("---")
try:
    command = [
        "aws",
        "s3",
        "sync",
        LOCAL_DATASET_PATH,
        f"{S3_DATASET_PATH}/v{VERSION}/",
        "--exact-timestamps",  # Ensures that timestamps are used for sync checks
    ]
    # Run the command
    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )

    # Read and print stdout line by line in real-time
    for line in process.stdout:
        sys.stdout.write(line)
        sys.stdout.flush()

    # Wait for the process to finish and check if it succeeded
    process.wait()
    if process.returncode != 0:
        error_output = process.stderr.read()
        print("Error syncing folder to S3:", error_output)

except subprocess.CalledProcessError as e:
    print("An error occurred:", e)
