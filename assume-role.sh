#!/bin/bash

# Check if required commands are installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it first."
    exit 1
fi

# Variables
ROLE_ARN="arn:aws:iam::820242929398:role/infraUser-role" # Replace with your role ARN
SESSION_NAME="MySession"                                     # A unique session name
DURATION=28800                                              # Session duration in seconds (max 12 hours for CLI)

# Assume the role
echo "Assuming role: $ROLE_ARN..."
CREDENTIALS=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "$SESSION_NAME" --duration-seconds "$DURATION" 2>&1)

# Check if the assume-role command was successful
if [ $? -ne 0 ]; then
    echo "Failed to assume role. Error details: $CREDENTIALS"
    exit 1
fi

# Debugging: Output credentials for verification (optional, remove in production)
echo "CREDENTIALS output: $CREDENTIALS"

# Parse temporary credentials
export AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Credentials.SessionToken')

# Save credentials to a file (optional)
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" > aws_temp_credentials.sh
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> aws_temp_credentials.sh
echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" >> aws_temp_credentials.sh

# Source the credentials
source aws_temp_credentials.sh

# Verify credentials were set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
    echo "Failed to retrieve temporary credentials."
    exit 1
fi

# Output success message
echo "AWS credentials configured successfully for role: $ROLE_ARN"
echo "Session will expire in $(($DURATION / 60)) minutes."

# Test temporary credentials
echo "Testing temporary credentials with 'aws sts get-caller-identity'..."
aws sts get-caller-identity

# Optional: List S3 buckets to confirm permissions
echo "Listing S3 buckets..."
aws s3 ls



