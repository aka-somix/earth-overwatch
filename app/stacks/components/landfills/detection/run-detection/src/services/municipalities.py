import requests


class MunicipalityService:
    def __init__(self, base_url):
        self.base_url = base_url

    def get_municipalities_by_region(self, region_id):
        url = f"{self.base_url}/geo/municipalities"
        params = {"region": region_id}
        response = requests.get(url, params=params, timeout=5)

        if response.status_code == 200:
            return response.json()
        else:
            return {"error": response.json()}
