#!/bin/bash
# AuthorizeOrg.sh
# Authorizes a Salesforce org using JWT and AES-encrypted key

set -e

# Debug: print lengths of secrets (safe)
echo "🔐 Authorizing org $SANDBOX_NAME..."
echo "AESKEY length: ${#AESKEY}"
echo "IVKEY length: ${#IVKEY}"
echo "ENCRIPTED_KEY length: ${#ENCRIPTED_KEY}"
echo "CONSUMER_KEY length: ${#CONSUMER_KEY}"
echo "USER_NAME length: ${#USER_NAME}"

# Skip if RUNAGAINSTORG is false
if [[ "$RUNAGAINSTORG" == "false" ]]; then
  echo "ℹ️ RUNAGAINSTORG=false, skipping org authorization"
  exit 0
fi

# Write encrypted key to file
echo "$ENCRIPTED_KEY" > encrypted_key.txt

# Decrypt JWT key using AESKEY and IVKEY
openssl enc -aes-256-cbc -md sha1 -nosalt -base64 -d \
  -in encrypted_key.txt \
  -out server.key \
  -K "$AESKEY" \
  -iv "$IVKEY"

# Authorize Salesforce org using JWT flow
sf org login jwt \
  -o "$USER_NAME" \
  -f server.key \
  -i "$CONSUMER_KEY" \
  -r "$INSTANCE_URL" \
  -s \s
  -a "$SANDBOX_NAME"

echo "✅ Successfully authorized org: $SANDBOX_NAME"

# Cleanup sensitive files
rm -f server.key encrypted_key.txt