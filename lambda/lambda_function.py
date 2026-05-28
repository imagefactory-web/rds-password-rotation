import boto3
import json
import logging
import os
import secrets
import string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def generate_password(length=16):
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def lambda_handler(event, context):
    try:
        rds_instance_id = os.environ["RDS_INSTANCE_ID"]
        rds_username = os.environ["RDS_USERNAME"]
        rds_host = os.environ["RDS_HOST"]
        secret_id = os.environ["SECRET_ID"]

        logger.info(f"Starting password rotation for RDS: {rds_instance_id}")

        new_password = generate_password()

        rds_client = boto3.client("rds")
        rds_client.modify_db_instance(
            DBInstanceIdentifier=rds_instance_id,
            MasterUserPassword=new_password,
            ApplyImmediately=True
        )

        secrets_client = boto3.client("secretsmanager")
        secrets_client.put_secret_value(
            SecretId=secret_id,
            SecretString=json.dumps({
                "username": rds_username,
                "password": new_password,
                "host": rds_host
            })
        )

        logger.info("Secrets Manager updated successfully")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Password rotation completed successfully",
                "instance": rds_instance_id
            })
        }

    except Exception as e:
        logger.error(f"Error during rotation: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }