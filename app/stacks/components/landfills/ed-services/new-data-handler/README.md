# Lambda Service: NEW DATA HANDLER

## Description

this handler containing the lambda used to manage event, invoice and programs

## Installation
```bash
yarn
```

## Input

In order for this Lambda Function to properly work the expected input is:
```json
{
    detail-type: "dataplatform/<whatever>",      # <-- <whatever> can be replaced with any string
    detail: {
        bbox: [
            xmin,
            ymin,
            xmax,
            ymax
        ],
        imageS3URL: "s3://your/path/to/img",    # <-- Optional, defaults to 4326
    }
}
```
