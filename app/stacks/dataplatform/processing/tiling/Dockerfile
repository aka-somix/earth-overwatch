FROM ghcr.io/osgeo/gdal:ubuntu-small-latest

# Set environment variable to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set the working directory in the container
WORKDIR /app

# Install Python dependencies
RUN apt-get update && apt-get install -y python3-boto3 python3-dotenv

# Copy the current directory contents into the container at /app
COPY ./src /app

CMD ["python3", "main.py"]
