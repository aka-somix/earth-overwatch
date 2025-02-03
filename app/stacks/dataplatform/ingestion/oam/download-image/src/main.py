"""
OAM INGESTION - Download metadata

Environment Variables:
- LANDINGZONE_BUCKET: S3 bucket to store metadata.
- OAM_ENDPOINT: OAM API endpoint.
- TIMEOUT: HTTP request timeout (default: 3s).
- PRODUCT: Metadata storage category (default: "oam").
- REGION: Geographic region (default: "italy").
"""

import sys
from os import environ
from datetime import datetime
import logging

# IMPORT EXTERNAL DEPENDENCIES
sys.path.append(".ext")
import requests
import boto3


# --- Logger config for AWS ---
logging.getLogger().setLevel(logging.INFO)

# --- PARAMETERS ---
LANDINGZONE_BUCKET = environ.get("LANDINGZONE_BUCKET")
HTTP_TIMEOUT = int(environ.get("TIMEOUT", "10"))
EVENT_REQUIRED_ATTRIBUTES = {"meta"}
META_REQUIRED_ATTRIBUTES = {"id", "date", "img_url"}

# --- BRONZE STORAGE PARTITIONING ---
PRODUCT = environ.get("PRODUCT") or "oam"
REGION = environ.get("REGION") or "italy"

# --- AWS CLIENTS ---
s3 = boto3.client("s3")


def validate_input_dict(event, required_attr):
    """Validates the input event for required parameters."""
    if not isinstance(event, dict):
        raise ValueError("Event payload must be a dictionary.")
    missing_keys = required_attr - event.keys()
    if missing_keys:
        raise ValueError(f"Missing required parameters: {', '.join(missing_keys)}")


def lambda_handler(event, _ctx):

    validate_input_dict(event, EVENT_REQUIRED_ATTRIBUTES)
    meta = event["meta"]
    logging.info(f"Metadata object to elaborate: {meta}")
    validate_input_dict(meta, META_REQUIRED_ATTRIBUTES)
    # Extract values from meta obj
    meta_id = meta["id"]
    meta_image_url = meta["img_url"]
    meta_date = (
        datetime.strptime(meta["date"], "%Y-%m-%d").date().isoformat()
    )

    # Stream the image and upload directly to S3
    logging.info(f"Getting stream data from: {meta_image_url}")
    response = requests.get(meta_image_url, stream=True, timeout=HTTP_TIMEOUT)
    response.raise_for_status()  # Raise an error for bad responses (4xx, 5xx)

    # Build key path on landingzone
    year, month, day = meta_date.split("-")
    data_key = f"{PRODUCT}/data/{REGION}/{year}/{month}/{day}/{meta_id}.tif"

    # Upload the streamed content to S3
    logging.info(f"Uploading to S3 at: s3://{LANDINGZONE_BUCKET}/{data_key}")
    s3.upload_fileobj(response.raw, LANDINGZONE_BUCKET, data_key)

    return {
        "img_s3_uri": f"s3://{LANDINGZONE_BUCKET}/{data_key}",
        "bbox": [0,0,0,0] # TODO Extract BBOX
    }