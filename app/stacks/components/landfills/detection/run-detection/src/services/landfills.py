import requests


class LandfillService:
    def __init__(self, base_url):
        self.base_url = base_url

    def create_landfill(self, municipality_id, detected_from, detection_time, geometry):
        url = f"{self.base_url}/landfills"
        payload = {
            "municipality_id": municipality_id,
            "detected_from": detected_from,
            "detection_time": detection_time,
            "geometry": geometry,
        }
        headers = {"Content-Type": "application/json"}
        response = requests.post(url, json=payload, headers=headers, timeout=5)

        if response.status_code == 201:
            return response.json()
        else:
            return {"error": response.json()}
