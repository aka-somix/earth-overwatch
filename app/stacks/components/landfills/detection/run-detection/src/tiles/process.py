from core.conf import logs


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
                process_fn(m)
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
