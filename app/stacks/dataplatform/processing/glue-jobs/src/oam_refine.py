"""
REFINE OAM; Processing job
--------------------------
"""

import sys
from awsglue.job import Job
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions

from sedona.spark import SedonaContext
from pyspark.sql.functions import col, explode, expr
from pyspark.sql.types import StringType, TimestampType, ArrayType, DoubleType


class OAMRefine:
    """
    Job Class for OAM Refine
    """

    def __init__(self):
        config = SedonaContext.builder().getOrCreate()
        sedona = SedonaContext.create(config)
        sc = sedona.sparkContext
        sc.setLogLevel("INFO")

        self.sc = GlueContext(sc)
        self.sedona = sedona
        self.job = Job(self.sc)
        self.job_name = "OAMR Refine processing"

        self.args = getResolvedOptions(
            sys.argv,
            [],
        )

        self.job.init(self.job_name, self.args)

    def run(self):
        """
        Glue Job function executed at each run
        """

        # Get the Glue Logger -> Logs go to the DRIVER stream
        logger = self.sc.get_logger()

        # Read JSON from S3
        json_path = "s3://scrnts-dev-dataplat-landing-zone-eu-west-1-772012299168/oam/metadata/italy/2024/04/08/1738591402.json"

        logger.info("JOB | Read JSON File")

        df = self.sedona.read.option("multiline", "true").json(json_path)

        # Explode the 'meta' array to create separate rows
        meta_df = df.withColumn("meta", explode(col("meta"))).select("meta.*")

        logger.info("JOB | Processing Data")

        # Create Geometry from footprint
        meta_df = meta_df.withColumn("geometry", expr("ST_GeomFromText(footprint)"))

        # Compute geohashing
        meta_df = meta_df.withColumn(
            "geohash", expr("ST_GeoHash(geometry, 16)")
        ).repartition("geohash")

        # Cast the columns to the correct types
        final_df = meta_df.select(
            col("_id").alias("id").cast(StringType()),
            col("title").alias("acquisition_title").cast(StringType()),
            col("acquisition_start").cast(TimestampType()),
            col("acquisition_end").cast(TimestampType()),
            col("uploaded_at").cast(TimestampType()),
            col("bbox").cast(ArrayType(DoubleType())),
            col("geojson").cast(StringType()),
            col("geometry").cast(StringType()),
            col("geohash").cast(StringType()),
        )

        logger.info("JOB | Exporting Data into Parquet")

        # Store DF
        final_df.write.partitionBy("geohash").format("geoparquet").mode("append").save(
            "s3://scrnts-dev-dataplat-refined-data-eu-west-1-772012299168/oam/metadata/region=italy"
        )

        self.job.commit()


if __name__ == "__main__":
    OAMRefine().run()
