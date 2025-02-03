# Open Aerial Map Ingestion

Ingestion from the open project of: "Open Aerial Map" ([website](map.openaerialmap.org))


## Orchestration:

### Input payload
```json
{
    "start_date": <Start acquisition date>,
    "end_date": <End acquisition date>,
    "size": <Max size for acquisition>
}

```
#### Example:
```json
{
    "start_date": "2024-01-01",
    "end_date": "2024-02-01",
    "size": 1000
}
```

## How is ingestion made
OAM is ingested through a REST API exposed by the service

### Authentication
It seems like this is a **public API** that does not require auth. It is unclear if there are any **QUOTAS**.

### Endpoint
`metadata`: [http://api.openaerialmap.org/meta](http://api.openaerialmap.org/meta)

### Documentation
The full documentation is available at [https://docs.openaerialmap.org/](https://docs.openaerialmap.org/)