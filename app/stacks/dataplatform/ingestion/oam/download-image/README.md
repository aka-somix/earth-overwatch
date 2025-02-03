# Download Metadata Service

## Description

## Input
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

#### Example of input payload
```json
{
    "meta": {
        "id": "59e62b8a3d6412ef72209d62",
        "img_url": "http://oin-hotosm-temp.s3.amazonaws.com/581b063584ae75bb00ec7549/0/581b0892b0eae7f3b143a8ec.tif",
        "date": "2024-01-01"
    }
}
```

## Output

```json
{
    "img_s3_uri": <s3 uri>,
    "bbox": <bbox>
}
```
#### Example of output payload
```json
{
    "img_s3_uri": <s3 uri>,
    "bbox": <bbox>
}
```

