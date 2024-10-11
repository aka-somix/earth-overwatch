# Event Brokers

The events will be categorize based on the `detail-type`.
The event payload will be passed through the `detail` block. 

The other parts of the event can be used freely but are not standardized. Therefore is not assured they will be forward compatible.

### Example of event payload
```json
{
    "source": "service-123",
    "detail-type": "data/satellite/sentinel2",
    "detail": {
        "latitude": 12.3242,
        "longitude": 32.432
    } 
}
```
## Data Platform Broker
TBD


## Backend For Frontend Broker
TBD