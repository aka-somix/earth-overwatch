# SageMaker PyTorch image
FROM 763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-training:2.5.1-gpu-py311-cu124-ubuntu22.04-sagemaker

# INPUT VARIABLES
ARG VERSION
ARG MODEL_CHECKPOINT="yolo.pt"
ARG YOLO_BASE_MODEL_URL

ENV PATH="/opt/ml/code:${PATH}"

# this environment variable is used by the SageMaker PyTorch container to determine our user code directory.
ENV SAGEMAKER_SUBMIT_DIRECTORY /opt/ml/code

# Other Env variables
ENV MODEL_CHECKPOINT=${MODEL_CHECKPOINT}
ENV VERSION=${VERSION}

# Download YOLO checkpoint
RUN wget ${YOLO_BASE_MODEL_URL} -O /opt/ml/code/${MODEL_CHECKPOINT}

# Install YOLO requirements
COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# /opt/ml and all subdirectories are utilized by SageMaker, use the /code subdirectory to store your user code.
COPY src /opt/ml/code

# Defines script entrypoint
ENV SAGEMAKER_PROGRAM test.py