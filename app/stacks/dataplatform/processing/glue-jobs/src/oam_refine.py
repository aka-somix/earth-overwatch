"""
REFINE OAM; Processing job
--------------------------
"""

import sys
from awsglue.job import Job
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions

from sedona.spark import SedonaContext
from pyspark.sql.functions import col, explode, expr, current_timestamp
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
        self.job_name = "OAM Refine processing"

        self.args = getResolvedOptions(
            sys.argv,
            ["destination_table", "source_json_s3_path", "destination_s3_path"],
        )

        self.source_json_s3_path = self.args["source_json_s3_path"]
        self.destination_s3_path = self.args["destination_s3_path"]
        self.destination_table = self.args["destination_table"]

        self.job.init(self.job_name, self.args)

    def run(self):
        """
        Glue Job function executed at each run
        """

        # Get the Glue Logger -> Logs go to the DRIVER stream
        logger = self.sc.get_logger()

        logger.info("JOB | Read JSON File")

        json_df = self.sedona.read.option("multiline", "true").json(
            self.source_json_s3_path
        )

        # Explode the 'meta' array to create separate rows
        newmeta_df = json_df.withColumn("meta", explode(col("meta"))).select("meta.*")

        logger.info("JOB | Processing Data")

        # Create Geometry from footprint
        newmeta_df = newmeta_df.withColumn(
            "geometry", expr("ST_GeomFromText(footprint)")
        )

        # Compute geohashing
        newmeta_df = newmeta_df.withColumn(
            "geohash", expr("ST_GeoHash(geometry, 16)")
        ).repartition("geohash")

        # Cast the columns to the correct types
        newmeta_df = newmeta_df.select(
            col("_id").alias("id").cast(StringType()),
            col("title").alias("acquisition_title").cast(StringType()),
            col("acquisition_start").cast(TimestampType()),
            col("acquisition_end").cast(TimestampType()),
            col("uploaded_at").cast(TimestampType()),
            col("bbox").cast(ArrayType(DoubleType())),
            col("geojson").cast(StringType()),
            col("geometry"),
            col("geohash").cast(StringType()),
        ).withColumn("last_processed", current_timestamp())

        logger.info("JOB | Exporting Data into Parquet")

        # Store DF
        newmeta_df.write.partitionBy("geohash").format("geoparquet").mode(
            "append"
        ).save(self.destination_s3_path)

        logger.info(f"JOB | Repartitioning Table {self.destination_table}")

        self.sedona.sql(
            f"""
            MSCK REPAIR TABLE {self.destination_table};
            """
        )

        self.job.commit()


if __name__ == "__main__":
    OAMRefine().run()
