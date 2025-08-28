#!/bin/sh
# citrix compromise alerting wrapper script, written by Bryan Fisher <brf2010@med.cornell.edu> <bryan.fisher797@gmail.com>
# Usage: ./webshell_alert.sh <splunk_url> <hec_token>


SPLUNK_URL="$1"
HEC_TOKEN="$2"
CHECK_SCRIPT_PATH="/var/nsinstall/TLPCLEAR_check_script_cve-2025-6543-v1.8.sh"
HOSTNAME=$(hostname)

if [ -z "$SPLUNK_URL" ] || [ -z "$HEC_TOKEN" ]; then
  echo "Usage: $0 <splunk_url> <hec_token>"
  exit 1
fi

# Run the check script and capture its output
output=$(sh $CHECK_SCRIPT_PATH)

# Extract the log path using grep and sed
log_path=$(echo "$output" | grep "Log saved to" | sed 's/^.*Log saved to //')
echo "Captured log path: $log_path"

if [ ! -f "$log_path" ]; then
  echo "Error: File '$log_path' not found."
  exit 1
fi

# Escape double quotes, newlines, and backslashes for JSON; drop content into a variable
ESCAPED_CONTENT=$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' "$log_path" | perl -0777 -pe 's/\n/\\n/g')

# Send to Splunk HEC
curl -k "$SPLUNK_URL" \
  -H "Authorization: Splunk $HEC_TOKEN" \
  -d "{\"host\": \"$HOSTNAME\", \
  \"source\":\"$log_path\", \
  \"event\": \"$ESCAPED_CONTENT\"}"

# do some cleanup to the log directory. citrix netscaler devices have fixed disk sizes because of reasons.
find /var/log/ -type f -iname "custom_checks*.log" -mtime +7 -delete