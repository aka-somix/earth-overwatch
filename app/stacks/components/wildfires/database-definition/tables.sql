CREATE TABLE event_detected (
    id 					SERIAL PRIMARY KEY,
    detected_from       CHAR(3)                                 -- SAT | SIG
    detection_time      TIMESTAMP
    created_at 			TIMESTAMP default CURRENT_TIMESTAMP,
    updated_at 			TIMESTAMP default CURRENT_TIMESTAMP
);

-- Used for segmented images
CREATE TABLE event_location_polygon (
    id 					SERIAL PRIMARY KEY,
    id_event_detected   INT not NULL
    area                GEOMETRY(MultiPolygon, 4326) not NULL   -- Using SRID 4326 for GPS coordinates (WGS84) 
    created_at 			TIMESTAMP default CURRENT_TIMESTAMP,
    updated_at 			TIMESTAMP default CURRENT_TIMESTAMP
);

-- Used for signalation based detection
CREATE TABLE event_location_point (
    id 					SERIAL PRIMARY KEY,
    id_event_detected   INT not NULL
    area                GEOMETRY(Point, 4326) not NULL   -- Using SRID 4326 for GPS coordinates (WGS84) 
    created_at 			TIMESTAMP default CURRENT_TIMESTAMP,
    updated_at 			TIMESTAMP default CURRENT_TIMESTAMP
);
