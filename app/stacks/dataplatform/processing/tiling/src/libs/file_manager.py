import abc
from os import path
import boto3
from libs.logs import log


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

    def __init__(self, source_bucket: str, dest_bucket: str):
        super().__init__()
        self.source_bucket = source_bucket
        self.dest_bucket = dest_bucket

        self.client = boto3.client("s3")

    def download(self, url, local_path):
        key = url
        file_name = url.split("/")[-1]
        local_file_path = path.join(local_path, file_name)
        log.info(f"Downloading s3://{self.source_bucket}/{key} to {local_file_path}")
        self.client.download_file(self.source_bucket, key, local_file_path)
        return local_file_path

    def upload(self, local_path, url):
        key = url
        self.client.upload_file(local_path, self.dest_bucket, key)
        log.info(f"Uploaded {local_path} to s3://{self.dest_bucket}/{key}")
