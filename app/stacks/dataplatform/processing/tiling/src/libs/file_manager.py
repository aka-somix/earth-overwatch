from os import path
import boto3


class IFileManager(object):
    """
    Interface for managing files
    """

    def download(self, from_path: str, to_path: str) -> str:
        """
        Opens a file from a given path
        """

    def upload(self, from_path: str, to_path: str):
        """
        Stores a file
        """


class LocalFileManager(IFileManager):
    """Manages Files on the local system"""

    def __init__(self, workdir: str):
        super().__init__()
        self.workdir = workdir

    def download(self, from_path, to_path):
        return path.join(self.workdir, to_path)

    def upload(self, from_path, to_path):
        return path.join(self.workdir, to_path)


class S3FileManager(IFileManager):
    """Manages Files on the local system"""

    def __init__(self, source_bucket: str, dest_bucket: str, key_prefix=""):
        super().__init__()
        self.source_bucket = source_bucket
        self.dest_bucket = dest_bucket
        self.key_prefix = key_prefix

        self.client = boto3.client("s3")

    def download(self, from_path, to_path):
        key = path.join(self.key_prefix, to_path)
        self.client.download_file(self.source_bucket, key, from_path)
        return path.join(path.curdir, to_path)

    def upload(self, from_path, to_path):
        key = path.join(self.key_prefix, to_path)
        self.client.upload_file(from_path, self.dest_bucket, key)
        print(f"Uploaded {from_path} to {to_path}")
