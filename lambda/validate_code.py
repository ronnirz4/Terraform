import json
import boto3
import os

s3_client = boto3.client('s3')


def lambda_handler(event, context):
    try:
        # Extract bucket name and file key from the event
        bucket_name = event['bucket']
        file_key = event['file_key']

        # Check if the file exists in the S3 bucket
        response = s3_client.head_object(Bucket=bucket_name, Key=file_key)

        return {
            'statusCode': 200,
            'body': json.dumps(f"File {file_key} exists in bucket {bucket_name}.")
        }
    except s3_client.exceptions.ClientError as e:
        # If file doesn't exist or there's any error
        return {
            'statusCode': 404,
            'body': json.dumps(f"Error: {str(e)}")
        }
