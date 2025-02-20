CREATE EXTENSION postgis;

CREATE TABLE landfills (
    id 					SERIAL PRIMARY KEY,
    id_municipality     INT NOT NULL,
    source              VARCHAR(20),                            -- Source Product (exmaple: aerial)
    detection_time      TIMESTAMP,
    confidence          SMALLINT                                -- normalized confidence * 100 (0,9 --> 90)
    status              CHAR(1) ,                               -- V(alid) | I(nvalid) | U(nknown)
    area                GEOMETRY(MultiPolygon, 4326),           -- Using SRID 4326 for GPS coordinates (WGS84) 
    point_location      GEOMETRY(Point, 4326),                  -- Using SRID 4326 for GPS coordinates (WGS84) 
    created_at 			TIMESTAMP default CURRENT_TIMESTAMP,
    updated_at 			TIMESTAMP default CURRENT_TIMESTAMP
);
