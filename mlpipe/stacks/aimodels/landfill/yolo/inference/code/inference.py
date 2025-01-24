"""
CUSTOM YOLO MODEL 
-----------------
Inference script
"""

import numpy as np
import torch, os, json, base64, cv2, time
from ultralytics import YOLO

def model_fn(model_dir):
    print("Istantiating YOLO Model")
    env = os.environ
    model = YOLO(os.path.join(model_dir, "yolo11m.pt"))
    return model


def input_fn(request_body, request_content_type):
    print(f"Parsing input from request with content-type: {request_content_type}")
    if "image" in request_content_type:
        print("Pre-processing decoding a base64 image into a cv2 object")
        jpg_original = base64.b64decode(request_body)
        jpg_as_np = np.frombuffer(jpg_original, dtype=np.uint8)
        parsed_input = cv2.imdecode(jpg_as_np, flags=-1)
    
    elif request_content_type == "application/json":
        print("Processing a cv2 object directly")
        parsed_input = request_body
    else:
        raise Exception("Unsupported content type: " + request_content_type)
    return parsed_input

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
        result = model(input_data)

    return result
        
def output_fn(prediction_output, content_type):
    print("Executing output_fn from inference.py ...")
    infer = {}
    for result in prediction_output:
        if 'boxes' in result._keys and result.boxes is not None:
            infer['boxes'] = result.boxes.cpu().numpy().data.tolist()
        if 'masks' in result._keys and result.masks is not None:
            infer['masks'] = result.masks.cpu().numpy().data.tolist()
        if 'keypoints' in result._keys and result.keypoints is not None:
            infer['keypoints'] = result.keypoints.cpu().numpy().data.tolist()
        if 'probs' in result._keys and result.probs is not None:
            infer['probs'] = result.probs.cpu().numpy().data.tolist()
    return json.dumps(infer)