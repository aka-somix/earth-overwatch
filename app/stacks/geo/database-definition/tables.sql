CREATE TABLE municipality (
    id 					SERIAL PRIMARY KEY,
    name 				VARCHAR(255) not NULL,
    boundaries 			GEOMETRY(MultiPolygon, 4326) not NULL -- Using SRID 4326 for GPS coordinates (WGS84) 
);

CREATE TABLE wildfire_monitoring (
    id 					SERIAL PRIMARY KEY,
    id_municipality 	INT NOT NULL,
    counter 			INT default 0,
    created_at 			TIMESTAMP default CURRENT_TIMESTAMP,
    updated_at 			TIMESTAMP default CURRENT_TIMESTAMP
);
