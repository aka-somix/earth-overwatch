import json
from core.conf import logs
from core.geojson import bbox_to_geojson


class BBox(object):
    """Bounding box representation"""

    def __init__(self, x1, y1, x2, y2):
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2

    def to_dict(self):
        return {
            "xmin": self.x1,
            "ymin": self.y1,
            "xmax": self.x2,
            "ymax": self.y2,
        }

    def to_geojson(self):
        return bbox_to_geojson(self.to_dict())

    def to_geometry(self):
        return self.to_geojson()["geometry"]

    def __repr__(self):
        return f"BBOX: {self.to_dict()}"

    def __str__(self):
        return self.to_dict().__str__()


class TileMetadata(object):
    """Manages the Tile Metadata for inference"""

    def __init__(self, data):
        try:
            data_dict = json.loads(data)
            self.image_id = data_dict["originalImageId"]
            self._bbox = data_dict["originalBbox"]
            self.s3_uri_tile = data_dict["tileS3Uri"]
        except Exception as e:
            logs.error(f"Error: {e}")
            raise RuntimeError("Could not parse JSON payload into dict") from e

    def get_image_bbox(self) -> BBox:
        x1, y1, x2, y2 = self._bbox.values()
        return BBox(x1, y1, x2, y2)

    def get_tile_bbox(self) -> BBox:
        # TODO Implement it better
        return self.get_image_bbox()

    def __str__(self):
        return f"TILE METADATA: |{self.image_id} | {self._bbox.__str__()} | {self.s3_uri_tile}"

    def __repr__(self):
        return self.__str__()
