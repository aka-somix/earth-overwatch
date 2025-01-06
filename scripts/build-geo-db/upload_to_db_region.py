import psycopg2
import geojson
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Retrieve database connection parameters from environment variables
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_PORT = os.getenv("DB_PORT")

# Connect to your PostgreSQL database using environment variables
conn = psycopg2.connect(
    host=DB_HOST,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    port=DB_PORT,
)

# Create a cursor object to execute SQL commands
cur = conn.cursor()

# Load the GeoJSON file
geojson_file = "data/it_regions.geojson"

with open(geojson_file, "r", encoding="utf-8") as f:
    data = geojson.load(f)

features = data["features"]
batches = [features[i : i + 25] for i in range(0, len(features), 25)]

for idx, batch_features in enumerate(batches):
    print(f"Executing batch {idx}")

    # Iterate over each feature in the GeoJSON
    for feature in batch_features:
        # Extract the geometry (Polygon)
        geometry = feature["geometry"]

        # Extract the 'name' property from the feature's properties
        name = feature["properties"]["reg_name"]

        # Convert the geometry to WKT (Well-Known Text)
        geometry_wkt = geojson.dumps(geometry)

        print(f"Adding Query for: {name}")

        # Prepare the SQL query to insert into the 'region' table
        query = """
        INSERT INTO region (name, boundaries)
        VALUES (%s, ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326));
        """

        # Execute the query
        cur.execute(query, (name, geojson.dumps(geometry)))

    print(f"Committing batch {idx}")
    conn.commit()

# Close the database cursor and connection
cur.close()
conn.close()

print("Data inserted successfully.")
