#!/bin/bash
set -x
# Script to send email via AWS SES using SigV4 authentication and curl
# Usage: ./send_ses_email.sh [from_email] [to_email] [subject] [message]

# Check if required parameters are provided
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 from_email to_email subject message"
    echo "Example: $0 sender@example.com recipient@example.com \"Test Subject\" \"This is a test message\""
    exit 1
fi

# Parameters
FROM_EMAIL="$1"
TO_EMAIL="$2"
SUBJECT="$3"
MESSAGE="$4"

# AWS SES settings
AWS_REGION="ap-northeast-1"  # Change to your AWS region
SERVICE="ses"
# endpoint changed to email prefix instead of ses prefix
HOST="email.${AWS_REGION}.amazonaws.com"
ENDPOINT="https://${HOST}/v2/email/outbound-emails"

# Get AWS credentials from environment or profile
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    # Try to get from AWS CLI configuration
    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
    AWS_SESSION_TOKEN=$(aws configure get aws_session_token)

    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "Error: AWS credentials not found. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables or configure AWS CLI."
        exit 1
    fi
fi

# Create a date for headers and the credential string
DATE=$(date -u +"%Y%m%dT%H%M%SZ")
DATE_STAMP=$(date -u +"%Y%m%d")

# Create the JSON payload according to SES API v2
JSON_PAYLOAD="{\"Content\":{\"Simple\":{\"Body\":{\"Html\":{\"Charset\":\"utf8\",\"Data\":\"${MESSAGE}\"},\"Text\":{\"Charset\":\"utf8\",\"Data\":\"${MESSAGE}\"}},\"Subject\":{\"Charset\":\"utf8\",\"Data\":\"${SUBJECT}\"}}},\"Destination\":{\"ToAddresses\":[\"${TO_EMAIL}\"]},\"FromEmailAddress\":\"${FROM_EMAIL}\"}"
# Create the canonical headers
CANONICAL_HEADERS="content-type:application/json\nhost:${HOST}\nx-amz-date:${DATE}\n"
SIGNED_HEADERS="content-type;host;x-amz-date"

# Calculate the request body hash
REQUEST_BODY_HASH=$(printf "$JSON_PAYLOAD" | openssl dgst -sha256 | sed 's/^.* //')

# Create the canonical request
CANONICAL_REQUEST="POST\n/v2/email/outbound-emails\n\n${CANONICAL_HEADERS}\n${SIGNED_HEADERS}\n${REQUEST_BODY_HASH}"
# Create the string to sign
ALGORITHM="AWS4-HMAC-SHA256"
CREDENTIAL_SCOPE="${DATE_STAMP}/${AWS_REGION}/${SERVICE}/aws4_request"
STRING_TO_SIGN="${ALGORITHM}\n${DATE}\n${CREDENTIAL_SCOPE}\n$(printf "$CANONICAL_REQUEST" | openssl dgst -sha256 | sed 's/^.* //')"

# Calculate the signature
signature_key() {
    local key="AWS4$1"
    local dateStamp=$2
    local regionName=$3
    local serviceName=$4

    local kDate=$(printf "$dateStamp" | openssl dgst -sha256 -mac HMAC -macopt "key:$key" | sed 's/^.* //')
    local kRegion=$(printf "$regionName" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$kDate" | sed 's/^.* //')
    local kService=$(printf "$serviceName" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$kRegion" | sed 's/^.* //')
    local kSigning=$(printf "aws4_request" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$kService" | sed 's/^.* //')
    echo "$kSigning"
}

SIGNING_KEY=$(signature_key "$AWS_SECRET_ACCESS_KEY" "$DATE_STAMP" "$AWS_REGION" "$SERVICE")
SIGNATURE=$(printf "$STRING_TO_SIGN" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$SIGNING_KEY" | sed 's/^.* //')

# Create the authorization header
CREDENTIAL="Credential=${AWS_ACCESS_KEY_ID}/${CREDENTIAL_SCOPE}"
SIGNED_HEADERS_PARAM="SignedHeaders=${SIGNED_HEADERS}"
SIGNATURE_PARAM="Signature=${SIGNATURE}"
AUTHORIZATION_HEADER="${ALGORITHM} ${CREDENTIAL}, ${SIGNED_HEADERS_PARAM}, ${SIGNATURE_PARAM}"

# Create the session token header if it exists
SESSION_TOKEN_HEADER=""
if [ -n "$AWS_SESSION_TOKEN" ]; then
    SESSION_TOKEN_HEADER="-H \"X-Amz-Security-Token: ${AWS_SESSION_TOKEN}\""
fi

# Make the request
echo "Sending email from ${FROM_EMAIL} to ${TO_EMAIL}..."
RESPONSE=$(curl -s -X POST "${ENDPOINT}" \
    -H "Content-Type: application/json" \
    -H "Host: ${HOST}" \
    -H "X-Amz-Date: ${DATE}" \
    -H "Authorization: ${AUTHORIZATION_HEADER}" \
    ${SESSION_TOKEN_HEADER} \
    -d "${JSON_PAYLOAD}")

CURL_EXIT_CODE=$?

# Print the response
echo "Response from AWS SES:"
echo "$RESPONSE"
echo

if [ $CURL_EXIT_CODE -eq 0 ]; then
    echo "Email sent successfully!"
else
    echo "Failed to send email."
    exit 1
fi
