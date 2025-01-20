FROM python:3.11-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y gdal-bin python3-gdal && \
    apt-get clean

RUN pip install boto3

# Copy the current directory contents into the container at /app
COPY ./src /app

# Set the working directory in the container
WORKDIR /app

CMD ["python", "main.py"]