import os
import logging
from osgeo import gdal
from libs import file_manager as fm

# Use dotenv for local env
import dotenv

dotenv.load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,  # Change to DEBUG for more detailed logs
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Log to console
        logging.FileHandler("tile_processor.log")  # Log to file
    ]
)

# Constants
MODE = os.getenv("MODE")
TILE_SIZE = int(os.getenv("TILE_SIZE") or 600)

S3_BUCKET_SOURCE = os.getenv("S3_BUCKET_SOURCE")
S3_BUCKET_DESTINATION = os.getenv("S3_BUCKET_DESTINATION") or S3_BUCKET_SOURCE

FILE_NAME = os.getenv("FILE_NAME")
LOCAL_DIR = os.getenv("LOCAL_DIR") or "./.out"

def process_tile(dataset, xoff, yoff, xsize, ysize, output_path):
    """Process and save a tile."""
    try:
        gdal.Translate(output_path, dataset, srcWin=[xoff, yoff, xsize, ysize])
        logging.info(f"Generated tile: {output_path}")
    except Exception as e:
        logging.error(f"Failed to process tile {output_path}: {e}")
        raise

def validate_s3_mode():
    if S3_BUCKET_SOURCE is None:
        logging.critical('VALIDATION ERROR: S3_BUCKET_SOURCE not present')
        raise ValueError('VALIDATION ERROR: S3_BUCKET_SOURCE not present')
    if S3_BUCKET_DESTINATION is None:
        logging.critical('VALIDATION ERROR: S3_BUCKET_DESTINATION not present')
        raise ValueError('VALIDATION ERROR: S3_BUCKET_DESTINATION not present')
    if FILE_NAME is None:
        logging.critical('VALIDATION ERROR: FILE_NAME not present')
        raise ValueError('VALIDATION ERROR: FILE_NAME not present')

if __name__ == "__main__":

    logging.info("Starting tile processor script")

    try:
        if MODE == "LOCAL":
            file_manager = fm.LocalFileManager(".")
        elif MODE == "S3":
            validate_s3_mode()
            file_manager = fm.S3FileManager(
                S3_BUCKET_SOURCE, S3_BUCKET_DESTINATION, f"tiled{TILE_SIZE}"
            )
        else:
            logging.critical("MODE NOT DEFINED")
            raise Exception("MODE NOT DEFINED")

        # Download the GeoTIFF file from S3
        logging.info(f"Downloading file {FILE_NAME} from source")
        local_input_path = file_manager.download(FILE_NAME, FILE_NAME)

        # Open the dataset
        logging.info(f"Opening dataset {local_input_path}")
        dataset = gdal.Open(local_input_path)
        if dataset is None:
            logging.critical("Could not open the GeoTIFF file.")
            raise IOError("Could not open the GeoTIFF file.")

        # Extract file name
        image_file_name = os.path.splitext(os.path.basename(local_input_path))[0]

        # Get the size of the GeoTIFF
        width, height = dataset.RasterXSize, dataset.RasterYSize
        logging.info(f"GeoTIFF dimensions: width={width}, height={height}")

        # Create output directory if it doesn't exist
        os.makedirs(LOCAL_DIR, exist_ok=True)

        logging.info("Processing tiles sequentially")

        # Process each tile sequentially
        for xoff in range(0, width, TILE_SIZE):
            for yoff in range(0, height, TILE_SIZE):
                xsize = min(TILE_SIZE, width - xoff)
                ysize = min(TILE_SIZE, height - yoff)

                # Output file name
                output_filename = f"{image_file_name}_{xoff}_{yoff}_{xsize}x{ysize}.tif"
                output_local_path = os.path.join(LOCAL_DIR, output_filename)

                # Process the tile
                try:
                    process_tile(dataset, xoff, yoff, xsize, ysize, output_local_path)
                except Exception as e:
                    logging.error(f"Error processing tile at offset ({xoff}, {yoff}): {e}")

        # Upload generated tiles to S3
        logging.info("Uploading generated tiles to S3")
        for file in os.listdir(LOCAL_DIR):
            local_file_path = os.path.join(LOCAL_DIR, file)
            s3_key = f"tiles/{file}"

            try:
                file_manager.upload(local_file_path, s3_key)
                logging.info(f"Uploaded {local_file_path} to {s3_key}")
            except Exception as e:
                logging.error(f"Failed to upload {local_file_path} to S3: {e}")

        logging.info("Tile processing completed successfully")

    except Exception as e:
        logging.critical(f"Script failed: {e}")
        raise
