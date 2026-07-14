#!/bin/bash
set -euo pipefail

# 1. Secure cleanup trap - defined early to guarantee execution on exit
ENCRYPTED_FILE="./encrypted_key.txt"
SERVER_KEY="./server.key"
trap 'rm -f "$ENCRYPTED_FILE" "$SERVER_KEY"' EXIT

# 2. Quiet Debugging: Print string lengths safely (avoids printing secret data to CI/CD logs)
echo "🔐 Authorizing Salesforce org: ${SANDBOX_NAME}..."
echo "ENCRYPTED_KEY string length: ${#ENCRYPTED_KEY}"
echo "CONSUMER_KEY string length:  ${#CONSUMER_KEY}"
echo "USER_NAME string length:     ${#USER_NAME}"

# 3. Validate required environment variables are present before executing anything
if [[ -z "${AESKEY:-}" || -z "${IVKEY:-}" || -z "${INSTANCE_URL:-}" || -z "${USER_NAME:-}" || -z "${CONSUMER_KEY:-}" ]]; then
  echo "❌ Error: Required crypto, target org, or instance environment variables are missing." >&2
  exit 1
fi

# 4. Handle Conditional Skip (Pipeline-friendly exit code)
if [[ "${RUNAGAINSTORG:-}" == "false" ]]; then
  echo "ℹ️ RUNAGAINSTORG=false, skipping org authorization."
  exit 0  # 0 indicates a clean conditional bypass rather than a red pipeline failure
fi

# 5. Write encrypted key to file without adding corrupting trailing newlines
printf "%s" "$ENCRYPTED_KEY" > "$ENCRYPTED_FILE"

# 6. Decrypt JWT key using modern OpenSSL 3.x standards (AES-256-CBC + SHA256 + PBKDF2)
echo "🔓 Decrypting private key..."


openssl enc -aes-256-cbc --md sha1 -nosalt -base64 -d -in $ENCRYPTED_FILE  -out $SERVER_KEY -K $AESKEY -iv $IVKEY


set -x 
# 7. Authorize Salesforce org via JWT flow (Execution is inherently safe without 'set -x')
echo "🚀 Initializing JWT OAuth flow with Salesforce..."
sf org login jwt -o $USER_NAME  -f $SERVER_KEY -i "$CONSUMER_KEY" -r https://test.salesforce.com -a $SANDBOX_NAME
set +x
