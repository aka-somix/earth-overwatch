import json
from core.conf import logs, TILE_SIZE
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


def pixel_to_coordinates(ref_bbox: BBox, pix_bbox: BBox) -> BBox:
    """
    Convert bounding box pixel coordinates to geo-referenced coordinates.

    :param ref_bbox: BBox, geo-referenced extent of the original image
    :param px_bbox_list: list, bounding box in pixel coordinates [x1, y1, x2, y2, ...]
    :return: BBox, geo-referenced bounding box
    """

    # Compute scaling factors
    x_scale = (ref_bbox.x2 - ref_bbox.x1) / TILE_SIZE
    y_scale = (ref_bbox.y2 - ref_bbox.y1) / TILE_SIZE

    # Convert pixel coordinates to geo-referenced coordinates
    x1_geo = ref_bbox.x1 + pix_bbox.x1 * x_scale
    y1_geo = ref_bbox.y2 - pix_bbox.y1 * y_scale  # Invert y-axis (top-left origin)
    x2_geo = ref_bbox.x1 + pix_bbox.x2 * x_scale
    y2_geo = ref_bbox.y2 - pix_bbox.y2 * y_scale  # Invert y-axis (top-left origin)

    return BBox(x1_geo, y1_geo, x2_geo, y2_geo)


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
        # Extract coordinates from tile
        coordinates = [float(part) for part in self.s3_uri_tile.split(".tif")[0].split("_")[1:]]

        if len(coordinates) != 4:
            raise RuntimeError(f"Tile Coordinates found from s3 are not 4 as expected: {coordinates}")

        tile_pixel_bbox = BBox(*coordinates)
        return pixel_to_coordinates(self.get_image_bbox(), tile_pixel_bbox)

    def __str__(self):
        return f"TILE METADATA: |{self.image_id} | {self._bbox.__str__()} | {self.s3_uri_tile}"

    def __repr__(self):
        return self.__str__()
