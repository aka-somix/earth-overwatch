import re

def parse_s3_uri(s3_uri: str) -> dict:
    s3_uri_pattern = r"^s3:\/\/([^/]+)\/(.+)$"
    match = re.match(s3_uri_pattern, s3_uri)

    if match:
        bucket = match.group(1)
        key = match.group(2)
        return {"bucket": bucket, "key": key}
    
    raise ValueError("Invalid S3 URI format")
