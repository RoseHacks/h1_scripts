#!/bin/bash

# Grab the latest nuclei_input file
NUCLEI_INPUT=$(ls -t h1_scope_logs/nuclei_input_*.txt 2>/dev/null | head -n 1)

if [[ -z "$NUCLEI_INPUT" || ! -s "$NUCLEI_INPUT" ]]; then
  echo "[!] No valid nuclei_input file found — exiting."
  exit 1
fi

OUTPUT_DIR="h1_scope_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
NUCLEI_OUTPUT="$OUTPUT_DIR/nuclei_results_${TIMESTAMP}.json"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"

echo "[*] Running nuclei on $NUCLEI_INPUT..."
nuclei -l "$NUCLEI_INPUT" -severity low,medium,high,critical -silent -jsonl -o "$NUCLEI_OUTPUT"

echo "[✓] Nuclei results saved to $NUCLEI_OUTPUT"

# Send to Disocrd
FINDINGS=$(jq -r '
  select(.info.severity | IN("low", "medium", "high", "critical")) |
  "[\(.info.severity)] \(.templateID) → \(.matched)"' "$NUCLEI_OUTPUT")

TOTAL=$(echo "$FINDINGS" | wc -l)

if [[ $TOTAL -gt 0 ]]; then
  LIMITED=$(echo "$FINDINGS" | head -n 10)
  MESSAGE="🚨 **Nuclei Findings** ($TOTAL total)\n\`\`\`\n$LIMITED\n\`\`\`"
  curl -s -H "Content-Type: application/json" \
       -X POST \
       -d "{\"content\": \"$MESSAGE\"}" \
       "$DISCORD_WEBHOOK" > /dev/null

  echo "[✓] Sent $TOTAL findings to Discord."
else
  echo "[*] No Nuclei findings to report."
fi

echo "[✓] Done. Total Nuclei findings: $TOTAL"

