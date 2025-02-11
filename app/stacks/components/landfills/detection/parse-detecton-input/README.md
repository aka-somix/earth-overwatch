# Parse Detection Input Lambda

## Input Example

```json
{
    "version": "0",
    "id": "acf7c860-8b13-a7f1-ee10-8f15d7ab1b0c",
    "detail-type": "detect/landfills",
    "source": "components/landfill/newdata",
    "account": "772012299168",
    "time": "2025-02-11T15:34:23Z",
    "region": "eu-west-1",
    "resources": [],
    "detail": {
        "bbox": {
            "xmin": 9.446182,
            "ymin": 45.853165,
            "xmax": 9.446526,
            "ymax": 45.853345
        },
        "id": "678d1816b320a4000188968c",
        "s3Source": "s3://scrnts-dev-dataplat-refined-data-eu-west-1-772012299168/oam/tiles"
    }
}
```


## Output
```json
{
    Entries: [
        {
            Id: <sqs message id>
            MessageBody: {
                "originalBbox": {
                    "xmin": 9.446182,
                    "ymin": 45.853165,
                    "xmax": 9.446526,
                    "ymax": 45.853345
                },
                "tileS3Uri": "s3://scrnts-dev-dataplat-refined-data-eu-west-1-772012299168/oam/tiles/800/acf7c860-8b13-a7f1-ee10-8f15d7ab1b0c_1200_1200.tif"
            }
        }
    ]
}
```