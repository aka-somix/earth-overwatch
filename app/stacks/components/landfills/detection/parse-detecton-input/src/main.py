import os
import boto3
import logging

# --- Logger config for AWS ---
logging.getLogger().setLevel(logging.INFO)

# PARAMETERS
TILE_SIZE = os.getenv("TILE_SIZE", "800")

# AWS CLIENTS
s3 = boto3.client("s3")

def lambda_handler(event, _context):
    logging.info(f"Lambda function invoked with event: {event}")
    
    # Validate event structure
    if not isinstance(event, dict):
        logging.error("Invalid event format: expected a dictionary")
        raise ValueError("Invalid event format: expected a dictionary")

    detail = event.get("detail")
    if not isinstance(detail, dict):
        logging.error("Missing or invalid 'detail' field")
        raise ValueError("Missing or invalid 'detail' field")

    s3_source = detail.get("s3Source")
    original_bbox = detail.get("bbox")
    detection_id = detail.get("id")

    logging.info(f"Extracted values - s3Source: {s3_source}, bbox: {original_bbox}, id: {detection_id}")
    
    if not isinstance(s3_source, str) or not s3_source.startswith("s3://"):
        logging.error("Invalid or missing 's3Source' field")
        raise ValueError("Invalid or missing 's3Source' field")

    if not isinstance(original_bbox, dict) or not all(
        k in original_bbox for k in ["xmin", "ymin", "xmax", "ymax"]
    ):
        logging.error("Invalid or missing 'bbox' field")
        raise ValueError("Invalid or missing 'bbox' field")

    if not isinstance(detection_id, str) or not detection_id:
        logging.error("Invalid or missing 'id' field")
        raise ValueError("Invalid or missing 'id' field")

    # Parse S3 source to extract bucket and prefix
    s3_parts = s3_source[5:].split("/", 1)
    if len(s3_parts) < 2:
        logging.error("Invalid S3 Source format")
        raise ValueError("Invalid S3 Source format")

    bucket_name, base_prefix = s3_parts[0], s3_parts[1].rstrip("/")
    logging.info(f"Parsed bucket: {bucket_name}, prefix: {base_prefix}")

    # Construct full prefix
    full_prefix = f"{base_prefix}/{TILE_SIZE}/{detection_id}"
    logging.info(f"Constructed full S3 prefix: {full_prefix}")

    # List objects in S3 with the given prefix
    try:
        response = s3.list_objects_v2(Bucket=bucket_name, Prefix=full_prefix)
        logging.info(f"S3 list_objects_v2 response: {response}")
    except Exception as e:
        logging.error(f"Error listing S3 objects: {e}")
        raise

    entries = []

    if "Contents" in response:
        for obj in response["Contents"]:
            tile_s3_uri = f"s3://{bucket_name}/{obj['Key']}"
            
            entry = {
                "Id": obj["Key"].split("/")[-1],  # Using the filename as ID
                "MessageBody": {
                    "originalBbox": original_bbox,
                    "tileS3Uri": tile_s3_uri,
                },
            }
            entries.append(entry)
            logging.info(f"Added entry: {entry}")

    else:
        logging.warning('No Contents found in response')

    logging.info(f"Final entries: {entries}")
    return {"Entries": entries}
