CREATE TABLE landfills (
    id 					SERIAL PRIMARY KEY,
    id_municipality     INT NOT NULL,
    source              VARCHAR(20),                            -- SAT | SIG
    detection_time      TIMESTAMP,
    area                GEOMETRY(MultiPolygon, 4326),           -- Using SRID 4326 for GPS coordinates (WGS84) 
    point_location      GEOMETRY(Point, 4326),                  -- Using SRID 4326 for GPS coordinates (WGS84) 
    created_at 			TIMESTAMP default CURRENT_TIMESTAMP,
    updated_at 			TIMESTAMP default CURRENT_TIMESTAMP
);
