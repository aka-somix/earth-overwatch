"""
RUN-DETECTION LAMBDA SERVICE
--------------------------------

Lambda function that runs detections over image tiles in order to locate illegal landfills and upload them
into the detections database
"""

import sys
from datetime import datetime

# IMPORT EXTERNAL DEPENDENCIES
# ! IMPORTANT: This should always be put BEFORE loading other modules
sys.path.append(".ext")

# Imports
from core.aws import sqs, s3, sagemaker
from core.conf import (
    logs,
    TILES_PER_RUN,
    DETECTION_QUEUE_URL,
    GEO_API_BASE_URL,
    LANDFILL_API_BASE_URL,
    SAGEMAKER_ENDPOINT,
)
from tiles import TileMetadata
from tiles.process import QueueProcessor
from tiles.detection import DetectionController
from services.geo import GeoService
from services.landfills import NewLandfillRequest, LandfillService
from services.image import S3ImageService
from services.inference import SagemakerInferenceService

# Inject Services Objects
geoservice = GeoService(GEO_API_BASE_URL)
landfillservice = LandfillService(LANDFILL_API_BASE_URL)
s3_imageservice = S3ImageService(s3)
inference_service = SagemakerInferenceService(sagemaker, endpoint=SAGEMAKER_ENDPOINT)
detection_ctrl = DetectionController(inference_service, s3_imageservice)


def process_message(tile: TileMetadata):
    logs.info(f"Processing {tile}")
    image_bbox = tile.get_image_bbox()
    print(f"Image BBox: {image_bbox}")
    tile_bbox = tile.get_tile_bbox()
    print(f"Tile BBox: {tile_bbox}")

    # Step 1 - Use inference in order to detect landfills
    detections = detection_ctrl.run(tile.s3_uri_tile, tile_bbox)

    logs.info(f"Uploading: {len(detections)} detections for image")

    # Step 2 - Get Municipality from detection
    for d in detections:
        logs.info(f"Creating detection: {d.bbox}")

        municipalities_list = geoservice.search_municipalities(d.bbox.to_geometry())

        logs.info(f"Municipalities retrieved: {municipalities_list}")

        if len(municipalities_list) == 0:
            logs.warning(
                f"SKIPPING detection. No municipality found for bbox: {d.bbox}"
            )
            continue

        municipality_id = municipalities_list[0]["id"]

        logs.info(f"DETECTION INSIDE MUNICIPALITY: {municipality_id}")

        # Step 3 - Create a landfill detection for each municipality found
        landfill_request_body = NewLandfillRequest(
            payload={
                "municipality_id": municipality_id,
                "geometry": d.bbox.to_geometry(),
                "detection_time": datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
                "detected_from": "AERIAL",
                "confidence": d.confidence,
                "imageURI": d.image_uri,
            }
        )
        response = landfillservice.create_landfill(landfill_request_body)

        logs.info(f"Created landfill. Response: {response}")


def lambda_handler(event, _ctx):
    logs.info(f"Event received: {event}")

    processor = QueueProcessor(client=sqs, queue_url=DETECTION_QUEUE_URL)

    processor.process_batch(process_fn=process_message, size=TILES_PER_RUN)
