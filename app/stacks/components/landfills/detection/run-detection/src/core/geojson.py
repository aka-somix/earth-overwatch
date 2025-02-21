"""
Module for managing GeoJson data
"""


def bbox_to_geojson(bbox):
    """
    Convert a bounding box to a GeoJSON Polygon.

    Parameters:
        bbox (dict): A dictionary with xmin, ymin, xmax, ymax coordinates.

    Returns:
        dict: A GeoJSON dictionary representing the bounding box as a Polygon.
    """
    xmin, ymin, xmax, ymax = bbox["xmin"], bbox["ymin"], bbox["xmax"], bbox["ymax"]

    # Define polygon coordinates in GeoJSON format (closing the loop)
    coordinates = [
        [
            [xmin, ymin],  # Bottom-left
            [xmax, ymin],  # Bottom-right
            [xmax, ymax],  # Top-right
            [xmin, ymax],  # Top-left
            [xmin, ymin],  # Closing the loop
        ]
    ]

    # Construct GeoJSON Feature
    geojson = {
        "type": "Feature",
        "geometry": {"type": "Polygon", "coordinates": coordinates},
        "properties": {},
    }

    return geojson
