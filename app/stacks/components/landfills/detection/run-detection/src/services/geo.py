from typing import Any
import requests

from core.conf import API_KEY
from core.conf import logs


class GeoService:
    """
    Wraps the GEO REST API
    """

    def __init__(self, base_url):
        self.base_url = base_url

    def search_municipalities(self, geometry: dict[Any]):
        url = f"{self.base_url}/geo/municipalities/search"

        headers = {"Content-Type": "application/json", "x-api-key": API_KEY}
        payload = {"geometry": geometry}

        logs.info(f"Requesting {url} with BODY: {payload}")

        response = requests.post(url, json=payload, headers=headers, timeout=5)

        logs.debug(f"HTTP POST Request to {url} successfull")

        if response.status_code == 200:
            return response.json()
        elif response.status_code == 400:
            return {"error": "Invalid request payload"}
        elif response.status_code == 404:
            return {"error": "No municipalities found within the given polygon"}
        else:
            return {"error": f"Unexpected error: {response.status_code}"}
