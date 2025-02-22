from abc import ABC, abstractmethod
import base64
import boto3
from urllib.parse import urlparse


class ImageService(ABC):
    @abstractmethod
    def download_base64_stream(self, s3_uri):
        raise NotImplementedError()


class S3ImageService(ImageService):
    def __init__(self, s3_client=None):
        """
        Initialize the S3ImageService with an optional S3 client.
        If no client is provided, it uses the default boto3 S3 client.
        """
        self.s3 = s3_client or boto3.client("s3")

    def download_base64_stream(self, s3_uri) -> str:
        """
        Downloads an image from the given S3 URI and returns it as a base64-encoded string.

        :param s3_uri: The S3 URI (e.g., s3://bucket-name/path/to/image.jpg)
        :return: Base64-encoded image string
        """
        parsed_uri = urlparse(s3_uri)
        bucket_name = parsed_uri.netloc
        object_key = parsed_uri.path.lstrip("/")

        response = self.s3.get_object(Bucket=bucket_name, Key=object_key)
        image_data = response["Body"].read()

        base64_encoded = base64.b64encode(image_data).decode("utf-8")
        return base64_encoded
