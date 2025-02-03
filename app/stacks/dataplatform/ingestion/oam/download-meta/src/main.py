import sys
from os import environ
import logging
import json
from time import time

# IMPORT EXTERNAL DEPENDENCIES
sys.path.append(".ext")
import requests
import boto3

logging.getLogger().setLevel(logging.INFO)

# --- PARAMETERS ---
LANDINGZONE_BUCKET = environ.get("LANDINGZONE_BUCKET")
OAM_ENDPOINT = environ.get("OAM_ENDPOINT")
ITALY_BBOX = "6.7499552751,36.619987291,18.4802470232,47.1153931748"  # https://gist.github.com/graydon/11198540
HTTP_TIMEOUT = int(environ.get("TIMEOUT", "3"))

# --- BRONZE STORAGE PARTITIONING ---
PRODUCT = environ.get("PRODUCT") or "oam"
GEOREGION = environ.get("GEOREGION") or "italy"

# --- AWS CLIENTS ---
s3 = boto3.client("s3")


def validate_input():
    pass


def fetch_metadata(*, start: str, end: str, size: int):
    # Assemble conditions
    acq_start_cond = f"acquisition_from='{start}'"
    acq_end_cond = f"acquisition_to='{end}'"
    bbox_cond = f"bbox={ITALY_BBOX}"
    size_cond = f"limit={size}&sort=asc&order_by=acquisition_start"

    url = f"{OAM_ENDPOINT}?{acq_start_cond}&{acq_end_cond}&{bbox_cond}&{size_cond}"

    logging.info(f"Sending request: GET {url}")

    try:
        response = requests.get(url, timeout=HTTP_TIMEOUT)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        raise e


def process_data(raw_data):
    if "results" not in raw_data:
        logging.error("Invalid data format: 'results' key missing.")
        return None, None

    results = raw_data["results"]
    extracted_meta = [
        {
            "id": entry["_id"],
            "img_url": entry["uuid"],
            "date": entry["acquisition_start"],
        }
        for entry in results
    ]
    return results, {"meta": extracted_meta}


def store_to_landingzone(data: dict, date: str):
    year, month, day = date.split("-")
    data_key = f"{PRODUCT}/{GEOREGION}/{year}/{month}/{day}/{int(time())}.json"

    logging.info(f"Storing request into s3://{LANDINGZONE_BUCKET}/{data_key}")
    s3.put_object(Bucket=LANDINGZONE_BUCKET, Key=data_key, Body=json.dumps(data))


def lambda_handler(event, _ctx):
    start_date = event["start_date"]
    end_date = event["end_date"]
    size = event["size"]

    logging.info(f"Retrieving metadata from {OAM_ENDPOINT}")
    logging.info(f"Date interval: {start_date} - {end_date}")
    logging.info(f"Maximum batch: {size} entries")

    # Step 1 - Fetch Metadata from source
    logging.info("Fetching Metadata from OAM source")
    data = fetch_metadata(start=start_date, end=end_date, size=size)
    logging.info("Data Fetched successfully")

    # Step 2 - Process data to extract and parse results
    logging.info("Processing data retrieved")
    original_meta, parsed_meta = process_data(data)

    logging.info(f"Retrieved metadata: {original_meta}")

    # Step 3 - Upload request metadata to S3 bucket
    store_to_landingzone(original_meta, start_date)
    logging.info(f"Uploaded metadata to Bucket {LANDINGZONE_BUCKET}")

    return parsed_meta
