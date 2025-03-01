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


# Assuming SagemakerPayload is defined somewhere
class MOCKInferenceService(InferenceService):
    def __init__(self, sagemaker, endpoint: str):
        self.sagemaker = sagemaker
        self.endpoint = endpoint

    def run(self, _payload: SagemakerPayload) -> dict:
        response = {
            "inference": [
                {
                    "confidence": 0.85,
                    "box": {
                        "x1": 0.0,
                        "y1": 0.0,
                        "x2": 94.97244,
                        "y2": 120.56053
                    }
                },
                {
                    "confidence": 0.90,
                    "box": {
                        "x1": 451.86618,
                        "y1": 451.95657,
                        "x2": 557.0896,
                        "y2": 625.43774
                    }
                },
                {
                    "confidence": 0.64,
                    "box": {
                        "x1": 142.01732,
                        "y1": 200.34567,
                        "x2": 300.12345,
                        "y2": 400.6789
                    }
                }
            ]
        }
        
        logs.info(f"MOCKED RESPONSE: {response}")
        
        return response
