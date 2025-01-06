CREATE EXTENSION postgis;

CREATE TABLE municipality (
    id 					SERIAL PRIMARY KEY,
    name 				VARCHAR(255) not NULL,
    id_region           INT not null,
    boundaries 			GEOMETRY(Geometry, 4326) not NULL -- Using SRID 4326 for GPS coordinates (WGS84) 
);

CREATE TABLE province (
    id 					SERIAL PRIMARY KEY,
    name 				VARCHAR(255) not NULL,
    id_region           INT not null,
    boundaries 			GEOMETRY(Geometry, 4326) not NULL -- Using SRID 4326 for GPS coordinates (WGS84) 
);

CREATE TABLE region (
    id 					SERIAL PRIMARY KEY,
    name 				VARCHAR(255) not NULL,
    boundaries 			GEOMETRY(Geometry, 4326) not NULL -- Using SRID 4326 for GPS coordinates (WGS84) 
);

CREATE TABLE landfill_monitoring (
    id 					SERIAL PRIMARY KEY,
    id_municipality 	INT NOT NULL,
    requested_by        VARCHAR(100) NOT null,
    requested_date      TIMESTAMP,
    created_at 			TIMESTAMP default CURRENT_TIMESTAMP,
    updated_at 			TIMESTAMP default CURRENT_TIMESTAMP
);
