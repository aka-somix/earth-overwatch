"""
CUSTOM YOLO MODEL
-----------------
Inference script
"""

import os
from io import BytesIO
from transformers import DetrImageProcessor, DetrForObjectDetection
import torch
from PIL import Image
import json

#
# --- PARAMETERS
#
CHECKPOINT_FOLDER = "../checkpoint"
SCORE_THRESHOLD = 0.75


def model_fn(model_dir):
    checkpoint_path = os.path.join(model_dir, CHECKPOINT_FOLDER)
    print(f"Istantiating DETR Model from checkpoint at {checkpoint_path}")

    detr = DetrForObjectDetection.from_pretrained(checkpoint_path)

    return detr


def input_fn(request_body, request_content_type) -> Image:
    print(
        f"From content type {request_content_type}, parsing request body: {request_body}"
    )

    image = None

    if request_content_type == "multipart/form-data":
        file = request_body["files"]["file"]
        image = Image.open(BytesIO(file.read())).convert("RGB")
    else:
        raise ValueError(f"Content-type {request_content_type} not supported!")

    return image


# Process an incoming inference request
def predict_fn(input_data, model):
    print("Executing inference on input data parsed")
    processor = DetrImageProcessor.from_pretrained("facebook/detr-resnet-50")

    inputs = processor(images=input_data, return_tensors="pt")
    outputs = model(**inputs)
    # convert outputs (bounding boxes and class logits) to COCO API
    # let's only keep detections with score > 0.9
    target_sizes = torch.tensor([input_data.size[::-1]])
    results = processor.post_process_object_detection(
        outputs, target_sizes=target_sizes, threshold=SCORE_THRESHOLD
    )[0]

    return results


def output_fn(results, _content_type):
    print(f"Parsing output from model {results}")

    infer = {"inference": []}

    for score, _, box in zip(results["scores"], results["labels"], results["boxes"]):
        box = [round(i, 2) for i in box.tolist()]
        print(
            f"Detected waste with confidence:"
            f"{round(score.item(), 3)} at location {box}"
        )
        infer["inference"].append({"confidence": round(score.item(), 3), "bbox": box})

    return json.dumps(infer)
