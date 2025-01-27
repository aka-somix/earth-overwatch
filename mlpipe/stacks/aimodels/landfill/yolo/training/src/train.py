from os import environ
from os import path
import logging
import shutil
from ultralytics import YOLO

# ---- PARAMETERS ----
DATASET_PATH = environ.get("DATASET_PATH", "/datasets/example")
MODEL_CHECKPOINT = environ.get("MODEL_CHECKPOINT", "yolo11s.pt")
VERSION = environ.get("VERSION", "0.0.0")
SAGEMAKER_ARTIFACT_DIR = "/opt/ml/model"
SAGEMAKER_WORK_DIR = "/opt/ml/code"
SAGEMAKER_FAILURE_FILE = "/opt/ml/output/failure"
SAGEMAKER_OUTPUT_FILE = "/opt/ml/output/data"

# Hyperparameters
epochs = 5
img_size = 800


# ---- LOGGING ----
log = logging.getLogger()
log.setLevel(logging.INFO)

# Setting up file handler for logging
file_handler = logging.FileHandler(SAGEMAKER_OUTPUT_FILE, mode="w")
formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
file_handler.setFormatter(formatter)
log.addHandler(file_handler)


# ---- TRAINING EXECUTION ----
try:
    # Define YOLO Model
    log.info(
        f"Using YOLO Model from checkpoint file [{MODEL_CHECKPOINT}] in directory: {SAGEMAKER_WORK_DIR}"
    )
    model = YOLO(path.join(SAGEMAKER_WORK_DIR, MODEL_CHECKPOINT))

    log.info(f"Training Model from dataset at: {DATASET_PATH}")
    results = model.train(
        data=path.join(DATASET_PATH, "dataset.yaml"),
        epochs=epochs,
        imgsz=img_size,
        project=SAGEMAKER_WORK_DIR,
    )

    log.info(f"Training Completed! Results: {results}")

    # Copy Best weights to ARTIFACT FOLDER
    best_weights_path = f"{SAGEMAKER_WORK_DIR}/best.pt"
    shutil.copy(best_weights_path, SAGEMAKER_ARTIFACT_DIR)
    log.info(f"Best weights copied to {SAGEMAKER_ARTIFACT_DIR}")

except Exception as e:
    log.error(f"Training failed with the exception: {e}", exc_info=True)
    # Store failure
    with open(SAGEMAKER_FAILURE_FILE, "w", encoding="utf-8") as err_file:
        err_file.write(str(e))
    raise e
