import json
from abc import ABC, abstractmethod
from core.conf import logs


class InferenceService(ABC):
    @abstractmethod
    def run(self, payload):
        raise NotImplementedError()


class DUMMYInferenceService(InferenceService):
    """
    DUMMY SERVICE; Just for testing
    """

    def run(self, payload):
        logs.info(f"DUMMY RUN with payload {payload}")
        return []


class SagemakerPayload:
    SUPPORTED_CONTENT_TYPES = ["application/json", "image/jpeg"]

    def __init__(self, content_type, body):
        if content_type not in SagemakerPayload.SUPPORTED_CONTENT_TYPES:
            raise ValueError(
                f"SagemakerPayload | Invalid content type. Use one of the supported: {",".join(SagemakerPayload.SUPPORTED_CONTENT_TYPES)}"
            )
        self.content_type = content_type
        self.body = body

    def get_body_as_json(self) -> str:
        return json.dumps(self.body)

    def __str__(self):
        decoded_body = (
            self.body.decode("utf-8")
            if isinstance(self.body, bytes)
            else str(self.body)
        )
        truncated_body = (
            decoded_body[:100] + "..." if len(decoded_body) > 100 else decoded_body
        )
        return f"SagemakerPayload[ ContentType: {self.content_type} | Body: {truncated_body} ]"

    def __repr__(self):
        return self.__str__()


class SagemakerInferenceService(InferenceService):
    def __init__(self, sagemaker, endpoint: str):
        self.sagemaker = sagemaker
        self.endpoint = endpoint

    def run(self, payload: SagemakerPayload):

        response = self.sagemaker.invoke_endpoint(
            EndpointName=self.endpoint,
            ContentType=payload.content_type,
            Body=payload.get_body_as_json(),
        )
        logs.info(f"Response from endpoint: {response}")

        result = json.loads(response["Body"].read().decode("utf-8"))

        return result
