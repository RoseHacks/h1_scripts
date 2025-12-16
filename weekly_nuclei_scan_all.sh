#!/bin/bash

set -e

BASE_DIR="h1_scope_logs"
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
DISCORD_WEBHOOK="<link>"

ALL_LIVE_FILE="${BASE_DIR}/all_live_urls_seen.txt"
NUCLEI_OUTPUT="${BASE_DIR}/weekly_nuclei_output_${TIMESTAMP}.json"

if [ ! -f "$ALL_LIVE_FILE" ]; then
  echo "[!] $ALL_LIVE_FILE not found. You need to run recon first."
  exit 1
fi

echo "[*] Running weekly Nuclei scan on known live targets..."
echo "[*] Targets: $(wc -l < "$ALL_LIVE_FILE") live URLs"

# Run Nuclei on all known live URLs
nuclei -l "$ALL_LIVE_FILE" \
  -severity low,medium,high,critical \
  -silent -jsonl -o "$NUCLEI_OUTPUT"

echo "[✓] Nuclei results saved to $NUCLEI_OUTPUT"

# Send ALL findings to Discord
echo "[*] Sending full Nuclei results to Discord..."

if [ ! -s "$NUCLEI_OUTPUT" ]; then
  echo "[*] No findings to report."
  exit 0
fi

counter=0
batch=""
batch_limit=1900  # Discord message content limit (2k max; we stay safe)

while IFS= read -r line; do
  severity=$(echo "$line" | jq -r '.info.severity')
  template=$(echo "$line" | jq -r '.templateID')
  url=$(echo "$line" | jq -r '.matched')
  
  entry="[$severity] $template → $url"

  if [[ $((${#batch} + ${#entry})) -gt $batch_limit ]]; then
    # Send current batch
    curl -s -X POST -H "Content-Type: application/json" \
      -d "{\"content\": \"🚨 **Weekly Nuclei Findings Batch**\n\`\`\`\n${batch}\n\`\`\`\"}" \
      "$DISCORD_WEBHOOK" > /dev/null
    batch=""
    sleep 1  # respect Discord rate limit
  fi

  batch+="${entry}\n"
  ((counter++))
done < "$NUCLEI_OUTPUT"

# Send any remaining results
if [[ -n "$batch" ]]; then
  curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"content\": \"🚨 **Weekly Nuclei Findings Batch**\n\`\`\`\n${batch}\n\`\`\`\"}" \
    "$DISCORD_WEBHOOK" > /dev/null
fi

echo "[✓] Sent $counter findings to Discord."

echo "[*] Findings summary:"
jq -r '.info.severity' "$NUCLEI_OUTPUT" | sort | uniq -c

