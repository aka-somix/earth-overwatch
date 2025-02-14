import json
from core.conf import logs


class SagemakerPayload:
    SUPPORTED_CONTENT_TYPES = ["application/json", "image/jpeg"]

    def __init__(self, content_type, body):
        if content_type not in SagemakerPayload.SUPPORTED_CONTENT_TYPES:
            raise ValueError(
                f"SagemakerPayload | Invalid content type. Use one of the supported: {",".join(SagemakerPayload.SUPPORTED_CONTENT_TYPES)}"
            )
        self.content_type = content_type
        self.body = body

    def __str__(self):
        return (
            f"SagemakerPayload[ ContentType: {self.content_type} | Body: {self.body} ]"
        )


class InferenceSagemaker(object):
    def __init__(self, client, endpoint: str):
        self.client = client
        self.endpoint = endpoint

    def run(self, payload: SagemakerPayload):
        response = self.client.invoke_endpoint(
            EndpointName=self.endpoint,
            ContentType=payload.content_type,
            Body=payload.body,
        )
        logs.info(f"Response from endpoint: {response}")

        result = json.loads(response["Body"].read().decode("utf-8"))

        return result
