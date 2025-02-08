import abc
from os import path
import boto3
from libs.logs import log
from urllib.parse import urlparse


class IFileManager(abc.ABC):
    """
    Interface for managing files
    """

    @abc.abstractmethod
    def download(self, url: str, local_path: str) -> str:
        """
        Opens a file from a given path
        """

    @abc.abstractmethod
    def upload(self, local_path: str, url: str):
        """
        Stores a file
        """


class LocalFileManager(IFileManager):
    """Manages Files on the local system"""

    def download(self, url, local_path):
        file_name = url.split("/")[-1]
        local_file_path = path.join(local_path, file_name)
        log.info(f"Retrieving {file_name} into {local_file_path}")
        return path.join(local_path, local_file_path)

    def upload(self, local_path, url):
        log.info(f"Nothing to do to upload {local_path} to {url}")
        pass


class S3FileManager(IFileManager):
    """Manages Files on the local system"""

    def __init__(self, dest_bucket: str):
        super().__init__()
        self.dest_bucket = dest_bucket

        self.client = boto3.client("s3")

    def download(self, url, local_path):
        # Parse the URL
        parsed_url = urlparse(url)
        # Extract bucket key and filename
        bucket = parsed_url.netloc
        key = parsed_url.path.lstrip("/")
        file_name = key.split("/")[-1]
        log.debug(f"Bucket: {bucket} | Key: {key}")

        # define where to save the file locally
        local_file_path = path.join(local_path, file_name)

        log.info(f"Downloading {url} to {local_file_path}")
        self.client.download_file(bucket, key, local_file_path)
        return local_file_path

    def upload(self, local_path, url):
        key = url
        self.client.upload_file(local_path, self.dest_bucket, key)
        log.info(f"Uploaded {local_path} to s3://{self.dest_bucket}/{key}")
