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

# Connect to your PostgreSQL database
conn = psycopg2.connect(
    host=DB_HOST,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    port=DB_PORT,
)

# Create a cursor object to execute SQL commands
cur = conn.cursor()

# Fetch region IDs dynamically from the 'region' table
region_mapping = {}
cur.execute("SELECT id, name FROM region;")
for row in cur.fetchall():
    region_id, region_name = row
    region_mapping[region_name] = region_id

print("Region mapping loaded:", region_mapping)

# Load the GeoJSON file
geojson_file = "data/municipi_it.json"

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
        name = feature["properties"]["name"]
        region_name = feature["properties"]["reg_name"]

        # Retrieve the region ID from the mapping
        region_id = region_mapping.get(region_name)
        if not region_id:
            print(
                f"Region '{region_name}' not found in database. Skipping municipality '{name}'."
            )
            continue

        # Convert the geometry to WKT (Well-Known Text)
        geometry_wkt = geojson.dumps(geometry)

        print(f"Adding Query for: {name}")

        # Prepare the SQL query to insert into the 'municipality' table
        query = """
        INSERT INTO municipality (name, id_region, boundaries)
        VALUES (%s, %s, ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326));
        """

        # Execute the query
        cur.execute(query, (name, region_id, geojson.dumps(geometry)))

    print(f"Committing batch {idx}")
    conn.commit()

# Close the database cursor and connection
cur.close()
conn.close()

print("Data inserted successfully.")
