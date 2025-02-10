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
        id: "ABDAADAD13443A",
        s3Source: "s3://your/prefix/to/images",
        bbox: [
            xmin,
            ymin,
            xmax,
            ymax
        ]
    }
}
```
