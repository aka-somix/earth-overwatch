"""
Configurations
"""

from os import environ
import logging


# -- ENVIRONMENT --
TILES_PER_RUN = int(environ.get("TILES_PER_RUN", "1"))
LANDFILL_API_BASE_URL = environ.get("LANDFILL_API_BASE_URL", "not-set")
GEO_API_BASE_URL = environ.get("GEO_API_BASE_URL", "not-set")
SAGEMAKER_ENDPOINT = environ.get("SAGEMAKER_ENDPOINT", "not-set")
DETECTION_QUEUE_URL = environ.get("DETECTION_QUEUE_URL", "not-set")

# -- LOGGING --
logs = logging.getLogger()
logs.setLevel(logging.INFO)
