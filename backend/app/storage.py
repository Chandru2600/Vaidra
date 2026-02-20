import os
from app.config import settings
import boto3
from botocore.client import Config

USE_S3 = settings.USE_S3

def upload_to_storage(local_path: str, object_name: str):
    if not USE_S3:
        # when not using S3, just return local filename path
        return {"url": local_path, "key": local_path}
    # Using S3-compatible storage
    s3 = boto3.client(
        "s3",
        endpoint_url=settings.S3_ENDPOINT or None,
        region_name=settings.S3_REGION or None,
        aws_access_key_id=settings.S3_ACCESS_KEY,
        aws_secret_access_key=settings.S3_SECRET_KEY,
        config=Config(signature_version="s3v4")
    )
    bucket = settings.S3_BUCKET
    s3.upload_file(local_path, bucket, object_name)
    url = f"{settings.S3_ENDPOINT.rstrip('/')}/{bucket}/{object_name}" if settings.S3_ENDPOINT else f"https://{bucket}.s3.amazonaws.com/{object_name}"
    return {"url": url, "key": object_name}
