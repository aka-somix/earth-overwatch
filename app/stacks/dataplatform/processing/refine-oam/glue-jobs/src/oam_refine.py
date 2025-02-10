"""
REFINE OAM; Processing job
--------------------------
"""

import sys
from awsglue.job import Job
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame

from sedona.spark import SedonaContext
from pyspark.sql import DataFrame
from pyspark.sql.functions import col, explode, expr, current_timestamp, lit
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
            ["destination_table", "source_json_s3_path", "destination_s3_path", "dynamodb_destination_table"],
        )

        self.source_json_s3_path = self.args["source_json_s3_path"]
        self.destination_s3_path = self.args["destination_s3_path"]
        self.destination_table = self.args["destination_table"]
        self.dynamodb_destination_table = self.args["dynamodb_destination_table"]

        # Get the Glue Logger -> Logs go to the DRIVER stream
        self.log = self.sc.get_logger()

        self.job.init(self.job_name, self.args)

    def __extract_json(self) -> DataFrame:
        self.log.info("JOB | Read JSON File")

        json_df = self.sedona.read.option("multiline", "true").json(
            self.source_json_s3_path
        )

        # Explode the 'meta' array to create separate rows
        return json_df.withColumn("meta", explode(col("meta"))).select("meta.*")

    def __load_to_datalake(self, df: DataFrame):
        self.log.info("JOB | Exporting Datalake in Parquet format (SNAPPY)")

        df.write.partitionBy("geohash").format("geoparquet").mode("append").save(
            self.destination_s3_path
        )

        self.log.info(f"JOB | Repartitioning Table {self.destination_table}")

        self.sedona.sql(
            f"""
            MSCK REPAIR TABLE {self.destination_table};
            """
        )

    def __load_to_dynamodb(self, df: DataFrame):
        # Add status
        dyf_with_status = DynamicFrame.fromDF(df.withColumn("status", lit("PENDING")), self.sc, "add_status_and_turn_into_dyf")
    
        # Write to dynamodb
        self.sc.write_dynamic_frame.from_options(
            frame=dyf_with_status,
            connection_type="dynamodb",
            connection_options={
                "dynamodb.output.tableName": self.dynamodb_destination_table,
                "dynamodb.throughput.write.percent": "1.0",
            },
        )

    def run(self):
        """
        Glue Job function executed at each run
        """

        # -- EXTRACT
        newmeta_df = self.__extract_json()

        # -- TRANSFORM
        self.log.info("JOB | Processing Data")

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

        # -- LOAD
        self.__load_to_datalake(newmeta_df)

        # Extract only id and bbox
        newdata_event_df = newmeta_df.select("id", col("bbox").cast(StringType()),)

        self.__load_to_dynamodb(newdata_event_df)

        self.job.commit()


if __name__ == "__main__":
    OAMRefine().run()
