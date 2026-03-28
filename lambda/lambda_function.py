import boto3
import json
import logging
import os
import secrets
import string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def generate_password(length=16):
    """Generate a random password"""
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def lambda_handler(event, context):
    try:
        # Get environment variables
        rds_instance_id = os.environ['RDS_INSTANCE_ID']
        rds_username = os.environ['RDS_USERNAME']
        ssm_parameter_path = os.environ['SSM_PARAMETER_PATH']
        
        logger.info(f"Starting password rotation for RDS: {rds_instance_id}")
        
        # Generate new password
        new_password = generate_password()
        logger.info("New password generated")
        
        # Update RDS password
        rds_client = boto3.client('rds')
        response = rds_client.modify_db_instance(
            DBInstanceIdentifier=rds_instance_id,
            MasterUserPassword=new_password,
            ApplyImmediately=True
        )
        logger.info(f"Password updated for {rds_instance_id}")
        
        # Update SSM Parameter Store
        ssm_client = boto3.client('ssm')
        response = ssm_client.put_parameter(
            Name=ssm_parameter_path,
            Value=new_password,
            Type='SecureString',
            Overwrite=True
        )
        logger.info("SSM Parameter Store updated")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Password rotation completed successfully',
                'instance': rds_instance_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error during rotation: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }