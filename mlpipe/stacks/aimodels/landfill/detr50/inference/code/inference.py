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
CHECKPOINT_FOLDER = "../checkpoint"


def model_fn(model_dir):
    print("Istantiating DETR Model")
    pretrained = os.path.join(model_dir, CHECKPOINT_FOLDER)
    return None


def input_fn(request_body, request_content_type):
    print(f"From content type {request_content_type}, parsing request body: {request_body}")
    return None

# Process an incoming inference request
def predict_fn(input_data, model):
    print("Executing inference on input data parsed")
    return {}


def output_fn(prediction_output, _content_type):
    print(f"Parsing output from model {prediction_output}")
    return {}
