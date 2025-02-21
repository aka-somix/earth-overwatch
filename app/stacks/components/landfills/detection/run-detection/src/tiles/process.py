from core.conf import logs
from core.geojson import bbox_to_geojson
import json


class TileMetadata(object):
    """Manages the Tile Metadata for inference"""

    def __init__(self, data):
        try:
            data_dict = json.loads(data)
            self.image_id = data_dict["originalImageId"]
            self._bbox = data_dict["originalBbox"]
            self.s3_uri_tile = data_dict["tileS3Uri"]
        except Exception as e:
            logs.error(f"Error: {e}")
            raise RuntimeError("Could not parse JSON payload into dict") from e

    def get_image_bbox(self, *, mode: str):
        if mode == "GEOJSON":
            return bbox_to_geojson(self._bbox)
        else:
            return self._bbox

    def get_tile_bbox(self, *, mode: str):
        # TODO Implement it better
        return self.get_image_bbox(mode=mode)

    def __str__(self):
        return f"TILE METADATA: |{self.image_id} | {self._bbox.__str__()} | {self.s3_uri_tile}"

    def __repr__(self):
        return self.__str__()


class QueueProcessor(object):
    def __init__(self, client, queue_url: str, wait_time=10):
        """
        Initializes the QueueExtractor with the given SQS queue URL.

        :param queue_url: URL of the SQS queue
        :param max_messages: Maximum number of messages to fetch in a batch (default: 10)
        :param wait_time: Wait time in seconds for long polling (default: 5)
        """
        self._sqs = client
        self.queue_url = queue_url
        self.wait_time = wait_time

    def process_batch(self, *, size, process_fn):
        logs.info(f"Retrieving batch messages of size: {size} from {self.queue_url}")
        messages = self.__get_batch_tiles(size)
        logs.info(f"Retrieved {len(messages)} messages from queue")

        for m in messages:
            try:
                # Run processing function
                logs.info(f"Processing message {m}")

                # prepare tile object from body
                tile = TileMetadata(m["Body"])

                # Run custom processing function
                process_fn(tile)

                logs.info("Message successfully processed. Deleting it from queue")
                self.__delete_message(m)
                logs.info("Message deleted")
            except Exception as e:
                print(f"Message Error: {e}")

    def __get_batch_tiles(self, size: int):
        """
        Retrieves a batch of messages from the SQS queue.

        :param size: Number of messages to retrieve (up to max_messages)
        :return: List of messages
        """

        response = self._sqs.receive_message(
            QueueUrl=self.queue_url,
            MaxNumberOfMessages=size,
            WaitTimeSeconds=self.wait_time,
            MessageAttributeNames=["All"],
        )

        messages = response.get("Messages", [])

        return messages

    def __delete_message(self, message):
        """
        Deletes a single message from the SQS queue.

        :param message: Message to delete
        """
        if not message:
            return

        self._sqs.delete_message(
            QueueUrl=self.queue_url, ReceiptHandle=message["ReceiptHandle"]
        )
