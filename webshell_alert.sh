#!/bin/sh

# Usage: ./upload_to_splunk.sh <file_path> <splunk_url> <hec_token>

FILE_PATH="$1"
SPLUNK_URL="$2"
HEC_TOKEN="$3"

HOSTNAME=$(hostname)

if [ -z "$FILE_PATH" ] || [ -z "$SPLUNK_URL" ] || [ -z "$HEC_TOKEN" ]; then
  echo "Usage: $0 <file_path> <splunk_url> <hec_token>"
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "Error: File '$FILE_PATH' not found."
  exit 1
fi

# Read file content
FILE_CONTENT=$(cat "$FILE_PATH")

# Escape double quotes and backslashes for JSON
ESCAPED_CONTENT=$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g' "$FILE_PATH")

# Send to Splunk HEC
curl -k "$SPLUNK_URL" \
  -H "Authorization: Splunk $HEC_TOKEN" \
  -d "{\"host\": \"$HOSTNAME\", \
  \"event\": \"$ESCAPED_CONTENT\"}"
