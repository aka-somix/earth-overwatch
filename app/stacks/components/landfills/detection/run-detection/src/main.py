"""
RUN-DETECTION LAMBDA SERVICE
--------------------------------

Lambda function that runs detections over image tiles in order to locate illegal landfills and upload them
into the detections database
"""

import sys

# IMPORT EXTERNAL DEPENDENCIES
# ! IMPORTANT: This should always be put BEFORE loading other modules
sys.path.append(".ext")

# Imports
from core.aws import sqs
from tiles.process import QueueProcessor, TileMetadata
from core.conf import (
    logs,
    TILES_PER_RUN,
    DETECTION_QUEUE_URL,
    GEO_API_BASE_URL,
    LANDFILL_API_BASE_URL,
)
from services.geo import GeoService
from services.landfills import NewLandfillRequest, LandfillService

# Inject Services Objects
geoservice = GeoService(GEO_API_BASE_URL)
landfillservice = LandfillService(LANDFILL_API_BASE_URL)


def process_message(tile: TileMetadata):

    logs.info(f"Processing {tile}")

    # Step 1 - Get Municipality from message
    tile_bbox = tile.get_tile_bbox(mode="GEOJSON")
    municipalities_list = geoservice.search_municipalities(tile_bbox["geometry"])

    logs.info(f"Municipalities retrieved: {municipalities_list}")

    # Extract Ids
    municipalities_ids = [m["id"] for m in municipalities_list]

    logs.info(f"TILE INSIDE MUNICIPALITIES: {municipalities_ids}")

    # TODO RUN INFERENCE on image

    for m_id in municipalities_ids:
        landfill_request_body = NewLandfillRequest(
            payload={
                "municipality_id": m_id,
                "geometry": tile_bbox["geometry"],
                "detection_time": "2025-03-01",
                "detected_from": "TEST",
                "confidence": 0,
                "imageURI": tile.s3_uri_tile,
            }
        )
        response = landfillservice.create_landfill(landfill_request_body)

        logs.info(f"Created landfill. Response: {response}")


def lambda_handler(event, _ctx):
    logs.info(f"Event received: {event}")

    processor = QueueProcessor(client=sqs, queue_url=DETECTION_QUEUE_URL)

    processor.process_batch(process_fn=process_message, size=TILES_PER_RUN)
