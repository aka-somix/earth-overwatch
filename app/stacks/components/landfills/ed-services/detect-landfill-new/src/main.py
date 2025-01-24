import os, logging, json, time
import boto3, botocore
import numpy as np
import cv2

from libs import utils

# ENV CONFIG
ENDPOINT_NAME = os.environ.get('ENDPOINT_NAME', 'not-set')
LOCAL_PATH = os.environ.get('LOCAL_PATH', '/tmp')
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')

logger = logging.getLogger()
logger.setLevel(
    # TODO: well... it could be better
    logging.ERROR if LOG_LEVEL == 'ERROR' else logging.WARNING if LOG_LEVEL == 'WARNING' else logging.DEBUG if LOG_LEVEL == 'DEBUG' else logging.INFO
)

# S3 BUCKETS DETAILS
s3 = boto3.client('s3')

# INFERENCE ENDPOINT DETAILS
config = botocore.config.Config(read_timeout=80)
sagemaker = boto3.client('runtime.sagemaker', config=config)
modelHeight, modelWidth = 800, 800


def download_image(s3_url) -> str:
    bucket, key = utils.parse_s3_uri(s3_url).values()
    filename = key.split("/")[-1]

    logger.debug(f"BUCKET: {bucket}, KEY: {key}, FILENAME: {filename}")
    
    out_path = f"{LOCAL_PATH}/{filename}"
    s3.download_file(bucket, key, out_path)

    return out_path


def inference(payload):
    # run inference
    start_time_iter = time.time()
    response = sagemaker.invoke_endpoint(EndpointName=ENDPOINT_NAME, ContentType='application/json', Body=payload)
    # get the output results
    result = json.loads(response['Body'].read().decode())
    end_time_iter = time.time()
    
    # get the total time taken for inference
    inference_time = round((end_time_iter - start_time_iter)*100)/100
    logger.info(f'Inference Completed. Inference time: {inference_time} ')

    return result


# RUNNING LAMBDA
def lambda_handler(event, _context):

    latitude = event['detail']['latitude']
    longitude = event['detail']['longitude']
    image_s3_url = event['detail']['imageS3Url']

    logging.info(f"Downloading image from {image_s3_url}")
    file_path = download_image(image_s3_url)

    logging.info(f"Parsing image from {file_path} into cv2 object")
    orig_image = cv2.imread(filename=file_path)
    if orig_image is None:
        logger.warning("Warning. No image found")
    
    # Pre process data and create payload
    logging.debug(f"Resizing cv2 object to {modelHeight}h x {modelWidth}w")
    image = cv2.resize(orig_image.copy(), (modelWidth, modelHeight), interpolation = cv2.INTER_AREA)
    
    logging.debug(f"Transforming into numpy array and preparing payload")
    data = np.array(image.astype(np.float32)/255.)
    payload = json.dumps([data.tolist()])

    logging.info("Running inference on sagemaker")
    inf_result = inference(payload)

    logger.info(f"Inference result: {inf_result}")

    # OUTPUTS - Using the output to utilize in other services downstream
    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"result": inf_result}),
    }

