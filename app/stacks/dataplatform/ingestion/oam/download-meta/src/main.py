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
import logging
import json
from time import time
from collections import defaultdict
from datetime import datetime

# IMPORT EXTERNAL DEPENDENCIES
sys.path.append(".ext")
import requests
import boto3

logging.getLogger().setLevel(logging.INFO)

# --- PARAMETERS ---
LANDINGZONE_BUCKET = environ.get("LANDINGZONE_BUCKET")
OAM_ENDPOINT = environ.get("OAM_ENDPOINT")
ITALY_BBOX = "6.7499552751,36.619987291,18.4802470232,47.1153931748"
HTTP_TIMEOUT = int(environ.get("TIMEOUT", "3"))
EVENT_REQUIRED_ATTRIBUTES = {"start_date", "end_date", "size"}

# --- BRONZE STORAGE PARTITIONING ---
PRODUCT = environ.get("PRODUCT") or "oam"
REGION = environ.get("REGION") or "italy"

# --- AWS CLIENTS ---
s3 = boto3.client("s3")


def validate_input(event):
    """Validates the input event for required parameters."""
    if not isinstance(event, dict):
        raise ValueError("Event payload must be a dictionary.")
    missing_keys = EVENT_REQUIRED_ATTRIBUTES - event.keys()
    if missing_keys:
        raise ValueError(f"Missing required parameters: {', '.join(missing_keys)}")
    if not isinstance(event["size"], int) or event["size"] <= 0:
        raise ValueError("'size' must be a positive integer.")


def fetch_metadata(*, start: str, end: str, size: int):
    url = f"{OAM_ENDPOINT}?acquisition_from={start}&acquisition_to={end}&bbox={ITALY_BBOX}&limit={size}&sort=asc&order_by=acquisition_start"
    logging.info(f"Sending request: GET {url}")
    try:
        response = requests.get(url, timeout=HTTP_TIMEOUT)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        raise e


def process_data(raw_data):

    def extract_date(timestamp: str):
        return datetime.strptime(timestamp, "%Y-%m-%dT%H:%M:%S.%fZ").date().isoformat()

    if "results" not in raw_data:
        logging.error("Invalid data format: 'results' key missing.")
        return None, None

    original_data = raw_data["results"]
    grouped_data = defaultdict(list)
    for entry in original_data:
        acquisition_day = extract_date(entry["acquisition_start"])
        grouped_data[acquisition_day].append(entry)

    daygrouped_meta = [{"day": day, "meta": meta} for day, meta in grouped_data.items()]
    extracted_meta = [
        {
            "id": entry["_id"],
            "img_url": entry["uuid"],
            "date": extract_date(entry["acquisition_start"]),
        }
        for entry in original_data
    ]
    return daygrouped_meta, {"meta": extracted_meta}


def store_to_bronze(data: dict):
    for daygroup in data:
        year, month, day = daygroup["day"].split("-")
        metadata = {"meta": daygroup["meta"]}
        data_key = (
            f"{PRODUCT}/metadata/{REGION}/{year}/{month}/{day}/{int(time())}.json"
        )
        logging.info(f"Storing request into s3://{LANDINGZONE_BUCKET}/{data_key}")
        s3.put_object(
            Bucket=LANDINGZONE_BUCKET, Key=data_key, Body=json.dumps(metadata)
        )


def lambda_handler(event, _ctx):
    """
    This service downloads metadata from the OAM endpoint and returns paths for downloading images as well.
    It follows these steps:
        1. Fetch metadata from the OAM API using a given date range and size limit.
        2. Process the retrieved data by grouping it by acquisition day and extracting relevant metadata.
        3. Store the processed metadata in an AWS S3 bucket under a structured partitioning format.

    """
    validate_input(event)
    start_date = event["start_date"]
    end_date = event["end_date"]
    size = event["size"]

    logging.info(f"Retrieving metadata from {OAM_ENDPOINT}")
    logging.info(f"Date interval: {start_date} - {end_date}")
    logging.info(f"Maximum batch: {size} entries")

    data = fetch_metadata(start=start_date, end=end_date, size=size)
    logging.info("Data Fetched successfully")

    logging.info("Processing data retrieved")
    daygrouped_meta, parsed_meta = process_data(data)
    logging.info(f"Retrieved metadata grouped by day: {daygrouped_meta}")

    store_to_bronze(daygrouped_meta)
    logging.info(f"Uploaded metadata to Bucket {LANDINGZONE_BUCKET}")

    return parsed_meta
