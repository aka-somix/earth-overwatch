# Download Metadata Service

## Description

## Input

```json
{
    "start_date": <start acquisition date>,
    "end_date": <end acquisition date>,
    "size": <how many metadata to retrieve>
}
```

#### Example of input payload
```json
{
    "start_date": "2025-01-01",
    "end_date": "2025-01-02",
    "size": 1000
}
```

## Output
```json
{
    "meta": [
        {
            "id": <metadata url>,
            "img_url": <url for downloading the image from source>,
            "date": <image acquisition date>
        },
        ...
    ]
}
```

#### Example of output payload
```json
{
    "meta": [
        {
            "id": "59e62b8a3d6412ef72209d62",
            "img_url": "http://oin-hotosm-temp.s3.amazonaws.com/581b063584ae75bb00ec7549/0/581b0892b0eae7f3b143a8ec.tif",
            "date": "2024-01-01"
        },
        ...
    ]
}
```
