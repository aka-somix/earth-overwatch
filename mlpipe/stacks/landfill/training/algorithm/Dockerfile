FROM python:3.10

RUN apt-get -y update && apt-get install -y --no-install-recommends \
    libusb-1.0-0-dev \
    libudev-dev \
    build-essential \
    ca-certificates && \
    rm -fr /var/lib/apt/lists/*

# Keep python from buffering the stdout - so the logs flushed quickly
ENV PYTHONUNBUFFERED=TRUE

# Don't compile bytecode
ENV PYTHONDONTWRITEBYTECODE=TRUE

ENV PATH="/opt/app:${PATH}"

ENV PYTHONPATH=.

COPY requirements.txt ./requirements.txt
RUN pip3 install -r requirements.txt

# Add src code
COPY src ./
RUN chmod +x train
