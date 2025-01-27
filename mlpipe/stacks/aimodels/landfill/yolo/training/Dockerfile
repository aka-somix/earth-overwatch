# Use a base image with Python and GPU support (if needed for training)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Define build-time arguments
ARG DATASET_PATH
ARG VERSION
ARG MODEL_CHECKPOINT="yolo.pt"
ARG YOLO_BASE_MODEL_URL

# Set these arguments as environment variables to be available in the container
ENV DATASET_PATH=${DATASET_PATH}
ENV MODEL_CHECKPOINT=${MODEL_CHECKPOINT}
ENV VERSION=${VERSION}

# Install basic utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up Python environment
RUN python3 -m pip install --upgrade pip

# Install PyTorch (CUDA version should match your base image)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install YOLO dependencies
RUN pip install --no-cache-dir \
    numpy \
    matplotlib \
    opencv-python-headless \
    tqdm \
    boto3 \
    pyyaml \
    pandas \
    seaborn

RUN wget ${YOLO_BASE_MODEL_URL}} -O /opt/ml/code/${MODEL_CHECKPOINT}

# Install YOLO requirements
RUN pip install --no-cache-dir -r requirements.txt

# Copy the training script into the container
COPY src /opt/ml/code

WORKDIR /opt/ml/code

# SageMaker runs the training script as the container entry point
ENTRYPOINT ["python3", "/opt/ml/code/train.py"]
