# Lambda Service: NEW DATA HANDLER

## Description

this handler containing the lambda used to manage event, invoice and programs

## Installation
```bash
yarn
```

## Expected Input

In order for this Lambda Function to properly work the expected input is:
```json
{
    detail-type: "synthetized/<whatever>",      # <-- <whatever> can be replaced with any string
    detail: {
        longitude: 13.23423,                    # <-- Longitude from the center of the image
        latitude: 32.12313,                     # <-- Latitude from the center of the image
        imageS3URL: "s3://your/path/to/img",    # <-- Optional, defaults to 4326
    }
}
```