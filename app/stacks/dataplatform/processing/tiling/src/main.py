import os
from osgeo import gdal
from libs import file_manager as fm
from libs.logs import log

# Use dotenv for local env
import dotenv

dotenv.load_dotenv()

# Constants
MODE = os.getenv("MODE")
TILE_SIZE = int(os.getenv("TILE_SIZE") or 600)

S3_SOURCE_URL = os.getenv("S3_SOURCE_URL")
S3_DEST_BUCKET = os.getenv("S3_DEST_BUCKET")
S3_DEST_PREFIX = os.getenv("S3_DEST_PREFIX")

FILE_NAME = os.getenv("FILE_NAME")
LOCAL_DIR = os.getenv("LOCAL_DIR") or "./.in"
PROCESSED_DIR = os.path.join(LOCAL_DIR, "processed")


def validate_s3_mode():
    missing_vals = []
    for val in [S3_SOURCE_URL, S3_DEST_BUCKET, S3_DEST_PREFIX]:
        if val is None:
            missing_vals.append(val)

    if len(missing_vals) > 0:
        log.critical(f"VALIDATION ERROR: {','.join(missing_vals)} not present")
        raise ValueError(f"VALIDATION ERROR: {','.join(missing_vals)} not present")


def process_tile(dataset, xoff, yoff, xsize, ysize, output_path):
    """Process and save a tile."""
    try:
        gdal.Translate(output_path, dataset, srcWin=[xoff, yoff, xsize, ysize])
        log.info(f"Generated tile: {output_path}")
    except Exception as e:
        log.error(f"Failed to process tile {output_path}: {e}")
        raise


if __name__ == "__main__":
    log.info("Starting tile processor script")

    try:
        if MODE == "LOCAL":
            file_manager = fm.LocalFileManager()
            source_url = os.path.join(LOCAL_DIR, FILE_NAME)
            dest_prefix = "./.out"
        elif MODE == "S3":
            validate_s3_mode()
            file_manager = fm.S3FileManager(
                S3_DEST_BUCKET,
            )
            source_url = S3_SOURCE_URL
            dest_prefix = S3_DEST_PREFIX

        else:
            log.critical("MODE NOT DEFINED")
            raise Exception("MODE NOT DEFINED")

        # Download the GeoTIFF file
        log.info(f"Downloading file {FILE_NAME} from source")
        local_input_path = file_manager.download(source_url, LOCAL_DIR)

        # Open the dataset
        log.info(f"Opening dataset {local_input_path}")
        dataset = gdal.Open(local_input_path)
        if dataset is None:
            log.critical("Could not open the GeoTIFF file.")
            raise IOError("Could not open the GeoTIFF file.")

        # Extract file name
        image_file_name = os.path.splitext(os.path.basename(local_input_path))[0]

        # Get the size of the GeoTIFF
        width, height = dataset.RasterXSize, dataset.RasterYSize
        log.info(f"GeoTIFF dimensions: width={width}, height={height}")

        # Create output directory if it doesn't exist
        os.makedirs(LOCAL_DIR, exist_ok=True)
        os.makedirs(PROCESSED_DIR, exist_ok=True)

        log.info("Processing tiles sequentially")

        # Process each tile sequentially
        for xoff in range(0, width, TILE_SIZE):
            for yoff in range(0, height, TILE_SIZE):
                xsize = min(TILE_SIZE, width - xoff)
                ysize = min(TILE_SIZE, height - yoff)

                # Output file name
                output_filename = f"{image_file_name}_{xoff}_{yoff}_{xsize}x{ysize}.tif"
                output_local_path = os.path.join(PROCESSED_DIR, output_filename)

                # Process the tile
                try:
                    process_tile(dataset, xoff, yoff, xsize, ysize, output_local_path)
                except Exception as e:
                    log.error(f"Error processing tile at offset ({xoff}, {yoff}): {e}")

        # Upload generated tiles
        log.info("Uploading generated tiles")
        for file in os.listdir(PROCESSED_DIR):
            local_file_path = os.path.join(PROCESSED_DIR, file)
            dest_url = os.path.join(dest_prefix, file)

            try:
                file_manager.upload(local_file_path, dest_url)
            except Exception as e:
                log.error(f"Failed to upload {local_file_path} to S3: {e}")

        log.info("Tile processing completed successfully")

    except Exception as e:
        log.critical(f"Script failed: {e}")
        raise
