#!/bin/sh

# Usage: ./upload_to_splunk.sh <file_path> <splunk_url> <hec_token>

SPLUNK_URL="$1"
HEC_TOKEN="$2"
CHECK_SCRIPT_PATH="/tmp/TLPCLEAR_check_script_cve-2025-6543-v1.8.sh"
HOSTNAME=$(hostname)

# run the check script

# Run the check script and capture its output
output=$(sh $CHECK_SCRIPT_PATH)

# Extract the log path using grep and sed
log_path=$(echo "$output" | grep "Log saved to" | sed 's/^.*Log saved to //')

# Use the log path later in the script
echo "Captured log path: $log_path"

FILE_PATH=$log_path


if [ -z "$SPLUNK_URL" ] || [ -z "$HEC_TOKEN" ]; then
  echo "Usage: $0 <splunk_url> <hec_token>"
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
