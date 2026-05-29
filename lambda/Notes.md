# Lambda Function - RDS Password Rotation Notes

## Purpose

This Lambda function automates RDS password rotation.

Instead of manually changing database passwords, the function:

1. Generates a new password
2. Updates the RDS master password
3. Updates AWS SSM Parameter Store
4. Returns a success response

---

# Imported Modules

```python
import boto3
import json
import logging
import os
import secrets
import string
```

---

## boto3

AWS SDK for Python.

Used to interact with AWS services.

Examples:

```python
boto3.client('rds')
boto3.client('ssm')
```

Services used:

* Amazon RDS
* AWS Systems Manager Parameter Store

---

## json

Used to create JSON responses.

Example:

```python
json.dumps()
```

Lambda returns responses in JSON format.

---

## logging

Used for CloudWatch Logs.

Example:

```python
logger.info()
logger.error()
```

Benefits:

* Troubleshooting
* Monitoring
* Auditing

---

## os

Used to read environment variables.

Example:

```python
os.environ['RDS_INSTANCE_ID']
```

Environment variables are safer than hardcoding values.

---

## secrets

Used to generate cryptographically secure passwords.

Example:

```python
secrets.choice()
```

More secure than Python's random module.

---

## string

Provides character sets.

Example:

```python
string.ascii_letters
string.digits
```

Used during password generation.

---

# Logger Configuration

```python
logger = logging.getLogger()
logger.setLevel(logging.INFO)
```

Purpose:

* Create logger object
* Enable INFO level logging

Examples:

```python
logger.info("Password rotation started")
logger.error("Rotation failed")
```

Logs appear in:

```text
CloudWatch Logs
```

---

# Password Generation Function

```python
def generate_password(length=16):
```

Purpose:

Generate a random secure password.

---

## Character Set

```python
alphabet = string.ascii_letters + string.digits
```

Includes:

```text
A-Z
a-z
0-9
```

Example:

```text
Abc123Xyz789QweR
```

---

## Generate Password

```python
return ''.join(
    secrets.choice(alphabet)
    for _ in range(length)
)
```

Default Length:

```text
16 characters
```

Every execution generates a different password.

---

# Lambda Handler

```python
def lambda_handler(event, context):
```

Entry point of Lambda execution.

Whenever Lambda is invoked:

```text
Lambda Handler Executes
```

---

# Step 1 - Read Environment Variables

```python
rds_instance_id = os.environ['RDS_INSTANCE_ID']
rds_username = os.environ['RDS_USERNAME']
ssm_parameter_path = os.environ['SSM_PARAMETER_PATH']
```

Purpose:

Retrieve configuration values.

---

## Example Values

```text
RDS_INSTANCE_ID=myapp-database

RDS_USERNAME=admin

SSM_PARAMETER_PATH=/myapp/rds-password
```

These values are supplied through Terraform.

---

# Step 2 - Start Logging

```python
logger.info(
    f"Starting password rotation for RDS: {rds_instance_id}"
)
```

Example Log:

```text
Starting password rotation for RDS: myapp-database
```

Visible in:

```text
CloudWatch Logs
```

---

# Step 3 - Generate New Password

```python
new_password = generate_password()
```

Example:

```text
XyZ123AbCd456EfG
```

Purpose:

Generate a fresh secure password for RDS.

---

# Step 4 - Create RDS Client

```python
rds_client = boto3.client('rds')
```

Purpose:

Connect Lambda to Amazon RDS APIs.

---

# Step 5 - Rotate RDS Password

```python
response = rds_client.modify_db_instance(
    DBInstanceIdentifier=rds_instance_id,
    MasterUserPassword=new_password,
    ApplyImmediately=True
)
```

Purpose:

Update RDS master password.

---

## Parameters

### DBInstanceIdentifier

```python
DBInstanceIdentifier=rds_instance_id
```

Example:

```text
myapp-database
```

Specifies which RDS instance to update.

---

### MasterUserPassword

```python
MasterUserPassword=new_password
```

Sets newly generated password.

---

### ApplyImmediately

```python
ApplyImmediately=True
```

Meaning:

```text
Apply change immediately
```

Without this:

```text
Change waits until maintenance window
```

---

# Important Note

Lambda does NOT connect to MySQL.

Instead:

```text
Lambda
    ↓
AWS RDS API
    ↓
ModifyDBInstance
    ↓
RDS Password Updated
```

This is a control plane operation.

---

# Step 6 - Log Success

```python
logger.info(
    f"Password updated for {rds_instance_id}"
)
```

Example:

```text
Password updated for myapp-database
```

---

# Step 7 - Create SSM Client

```python
ssm_client = boto3.client('ssm')
```

Purpose:

Connect Lambda to Parameter Store.

---

# Step 8 - Update SSM Parameter

```python
response = ssm_client.put_parameter(
    Name=ssm_parameter_path,
    Value=new_password,
    Type='SecureString',
    Overwrite=True
)
```

Purpose:

Store the new password.

---

## Parameter Name

```python
Name=ssm_parameter_path
```

Example:

```text
/myapp/rds-password
```

---

## Parameter Value

```python
Value=new_password
```

Stores the latest password.

---

## SecureString

```python
Type='SecureString'
```

Encrypts password.

Benefits:

* Secure storage
* KMS encryption support

---

## Overwrite

```python
Overwrite=True
```

Allows updating existing parameter.

Without this:

```text
ParameterAlreadyExists Error
```

---

# Step 9 - Log Success

```python
logger.info(
    "SSM Parameter Store updated"
)
```

Example:

```text
SSM Parameter Store updated
```

---

# Step 10 - Return Success Response

```python
return {
    'statusCode': 200,
    'body': json.dumps({
        'message':
        'Password rotation completed successfully',
        'instance': rds_instance_id
    })
}
```

Example Response:

```json
{
  "statusCode": 200,
  "body": {
    "message": "Password rotation completed successfully",
    "instance": "myapp-database"
  }
}
```

---

# Error Handling

```python
except Exception as e:
```

Catches unexpected failures.

Examples:

* Missing permissions
* Invalid RDS instance
* SSM access denied
* Network issues

---

# Log Error

```python
logger.error(
    f"Error during rotation: {str(e)}"
)
```

Example:

```text
Error during rotation:
AccessDeniedException
```

---

# Return Error Response

```python
return {
    'statusCode': 500,
    'body': json.dumps({
        'error': str(e)
    })
}
```

Example:

```json
{
  "statusCode": 500,
  "body": {
    "error": "AccessDeniedException"
  }
}
```

---

# End-to-End Execution Flow

```text
Lambda Invoked
       ↓
Read Environment Variables
       ↓
Generate New Password
       ↓
Call RDS ModifyDBInstance API
       ↓
RDS Password Updated
       ↓
Update SSM Parameter Store
       ↓
Return Success Response
```

---

# How It Integrates With Kubernetes

```text
Lambda
   ↓
SSM Parameter Store Updated
   ↓
External Secrets Operator
   ↓
Kubernetes Secret Updated
   ↓
Stakater Reloader
   ↓
Application Restarted
   ↓
Application Uses New Password
```

---

# Interview Questions

## Why use secrets module?

Because it generates cryptographically secure random values suitable for passwords.

---

## Why use SecureString?

To securely store passwords in SSM Parameter Store.

---

## Why use ApplyImmediately=True?

To update the RDS password immediately instead of waiting for a maintenance window.

---

## Does Lambda connect directly to MySQL?

No.

Lambda uses the AWS RDS API:

```text
modify_db_instance()
```

to change the password.

---

## Why store password in SSM?

To provide a centralized secure location that can be consumed by:

* External Secrets Operator
* Applications
* Automation tools

---

## What happens after Lambda updates SSM?

```text
SSM Updated
      ↓
External Secrets Operator Sync
      ↓
Kubernetes Secret Updated
      ↓
Reloader Restarts Pods
      ↓
Applications Use New Password
```
