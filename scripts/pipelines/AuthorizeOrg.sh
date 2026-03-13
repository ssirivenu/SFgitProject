#!/bin/bash
# Srii Seelam 2024-JUN-07 - Updated Authorisation process using JWT Bearer Flow

#Check if changes need to be run against org
echo "Authorizing org $SANDBOX_NAME started"
echo "AESKEY length: ${#AESKEY}"
echo "IVKEY length: ${#IVKEY}"
if [[ "$RUNAGAINSTORG" == "false" ]]
then
    echo "No changes will be validated/deployed because RUNAGAINSTORG is set to false"
    exit 1
fi
echo "$ENCRIPTED_KEY" > encrypted_key.txt
# Decrypt JWT key
openssl enc -aes-256-cbc -md sha1 -nosalt -base64 -d \
-in encrypted_key.txt \
-out server.key \
-K "$AESKEY" \
-iv "$IVKEY"

# Authorize Sandbox environment
sf org login jwt \
-o "$USER_NAME" \
-f server.key \
-i "$CONSUMER_KEY" \
-r "$INSTANCE_URL" \
-s \
-a "$SANDBOX_NAME"

if [ $? -eq 0 ]; then
    echo "Successfully authorized the org: $SANDBOX_NAME"
else
    echo "Failed to authorize the org. Please check the error above."
    exit 1
fi

# Remove credentials file
rm -f ./server.key
rm -f ./encrypted_key.txt
