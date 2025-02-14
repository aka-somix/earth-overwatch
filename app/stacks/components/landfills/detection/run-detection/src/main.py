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
from tiles.process import QueueProcessor
from core.conf import logs, TILES_PER_RUN, DETECTION_QUEUE_URL


def process_message(m):
    print(m)
    logs.info(m)


def lambda_handler(event, _ctx):
    logs.info(f"Event received: {event}")

    processor = QueueProcessor(client=sqs, queue_url=DETECTION_QUEUE_URL)

    processor.process_batch(process_fn=process_message, size=TILES_PER_RUN)
