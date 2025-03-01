from typing import List

from core.conf import logs
from services import image, inference
from tiles import BBox, pixel_to_coordinates


class DetectionResult:
    def __init__(self, bbox: BBox, confidence: float, image_uri: str):
        self.bbox = bbox
        self.confidence = confidence
        self.image_uri = image_uri

    def __repr__(self):
        return f"✅ Detection with confidence {self.confidence} for Image {self.image_uri} | bbox: {self.bbox}"


class DetectionController(object):
    """
    Controller for the detection process
    """

    def __init__(
        self,
        inference_service: inference.InferenceService,
        image_service: image.ImageService,
    ):
        self.inference_service = inference_service
        self.image_service = image_service

    def run(self, image_uri, ref_bbox: BBox) -> List[DetectionResult]:
        logs.info(f"Running Detection on image {image_uri} with bbox: {ref_bbox}")

        # Step 1 - Download image from image_uri
        image = self.image_service.download_base64_stream(image_uri)

        # Step 2 - Run inference on image
        payload = inference.SagemakerPayload(
            content_type="image/jpeg", body={"image": image}
        )

        inf_res = self.inference_service.run(payload)
        logs.info(f"Inference Results: {inf_res}")

        # Step 3 - Parse the results
        logs.info("Parsing resulting boxes")
        detections = []
        for inf in inf_res["inference"]:
            logs.debug(f"Now parsing result: {inf}")
            inf_box = BBox(
                inf["box"]["x1"], inf["box"]["y1"], inf["box"]["x2"], inf["box"]["y2"]
            )
            geobox = pixel_to_coordinates(ref_bbox, inf_box)
            confidence = inf["confidence"]
            DetectionResult(geobox, confidence, image_uri)

        return detections
