import requests

from core.conf import API_KEY
from core.conf import logs


class NewLandfillRequest(object):
    def __init__(self, payload: dict):
        self.municipality_id = payload["municipality_id"]
        self.detected_from = payload["detected_from"]
        self.detection_time = payload["detection_time"]
        self.geometry = payload["geometry"]
        self.confidence = payload["confidence"]
        self.image_uri = payload["imageURI"]


class LandfillService:
    def __init__(self, base_url):
        self.base_url = base_url

    def create_landfill(self, body: NewLandfillRequest):
        url = f"{self.base_url}/detections"
        payload = {
            "municipality_id": body.municipality_id,
            "detected_from": body.detected_from,
            "detection_time": body.detection_time,
            "geometry": body.geometry,
            "confidence": body.confidence,
            "imageURI": body.image_uri,
        }
        headers = {"Content-Type": "application/json", "x-api-key": API_KEY}

        logs.info(f"Requesting {url} with BODY: {payload}")

        response = requests.post(url, json=payload, headers=headers, timeout=5)

        logs.debug(f"HTTP POST Request to {url} successfull")

        if response.status_code == 201:
            return response.json()
        else:
            return {"error": response.json()}
