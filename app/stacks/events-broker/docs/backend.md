# Backend Events Catalog

## DETECT EVENT
This event when there is a new image in an area monitored for a certain type of event.

### Template Descripton:
```
{
    "detail-type" : "detect/<type>",
    "detail": {
        latitudine: <number>,
        longitudine: <number>,
        imageS3URL: "s3://<url>",
        source: <original_source>
    }
}
```

* **type**: Could be any kind of event covered by an existing component. Example: *landfills*  
* **original_source**: Is the original event source of the image

There may be different rules existing to cover each type of event that must be monitored