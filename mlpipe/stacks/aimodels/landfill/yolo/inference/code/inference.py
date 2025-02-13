"""
CUSTOM YOLO MODEL
-----------------
Inference script
"""

import os
import json
import base64
from typing import List
import cv2
import numpy as np
import torch
from ultralytics import YOLO
from ultralytics.engine.results import Results

#
# --- PARAMETERS
#
CHECKPOINT_FILENAME = "checkpoint.pt"


def model_fn(model_dir):
    print("Istantiating YOLO Model")
    model = YOLO(os.path.join(model_dir, CHECKPOINT_FILENAME))
    return model


def input_fn(request_body, request_content_type):
    print(f"Parsing input from request with content-type: {request_content_type}")
    if "image" in request_content_type:
        print("Pre-processing decoding a base64 image into a cv2 object")
        jpg_original = base64.b64decode(request_body)
        jpg_as_np = np.frombuffer(jpg_original, dtype=np.uint8)
        image = cv2.imdecode(jpg_as_np, flags=-1)
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    elif request_content_type == "application/json":
        print("Processing a cv2 object directly")
        image_rgb = request_body
    else:
        raise Exception("Unsupported content type: " + request_content_type)
    return image_rgb


# Process an incoming inference request
def predict_fn(input_data, model):
    print("Executing inference on input data parsed")
    if torch.cuda.is_available():
        print("Using CUDA")
        processor = "cuda"
    else:
        print("Using CPU")
        processor = "cpu"
    model.to(torch.device(processor))

    with torch.no_grad():
        inference = model.predict(input_data, conf=0.15)

    return inference


def output_fn(prediction_output: List[Results], _content_type):
    print("Executing output_fn from inference.py ...")

    infer = {"inference": []}
    for res in prediction_output:
        res_dict = json.loads(res.to_json())
        for res_item in res_dict:
            infer["inference"].append(
                {"confidence": res_item["confidence"], "bbox": res_item["box"]}
            )
    return json.dumps(infer)
