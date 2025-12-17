#!/bin/bash
set -euo pipefail

BASE_DIR="h1_scope_logs"
DISCORD_WEBHOOK="<link>"
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")

# Locate newest new_domains_found file
NEW_DOMAINS_FILE=$(ls -t ${BASE_DIR}/new_domains_found_*.txt 2>/dev/null | head -n 1 || true)

if [[ -z "${NEW_DOMAINS_FILE}" || ! -s "${NEW_DOMAINS_FILE}" ]]; then
  echo "[!] No new_domains_found file detected or file is empty — exiting."
  exit 0
fi

# Output files
WILDCARD_INPUT="${BASE_DIR}/wildcard_domains_${TIMESTAMP}.txt"
SUBFINDER_OUTPUT="${BASE_DIR}/subfinder_results_${TIMESTAMP}.txt"
HTTPX_INPUT="${BASE_DIR}/httpx_input_${TIMESTAMP}.txt"
HTTPX_OUTPUT="${BASE_DIR}/httpx_results_${TIMESTAMP}.txt"
NUCLEI_INPUT="${BASE_DIR}/nuclei_input_${TIMESTAMP}.txt"
ALL_LIVE_FILE="${BASE_DIR}/all_live_urls_seen.txt"

# Parse domains
grep '^*\.' "$NEW_DOMAINS_FILE" | sed 's/^\*\.//' > "$WILDCARD_INPUT" || true
grep -v '^*\.' "$NEW_DOMAINS_FILE" > "$HTTPX_INPUT" || true

WILDCARD_COUNT=$(wc -l < "$WILDCARD_INPUT" || echo 0)
echo "[+] Saved ${WILDCARD_COUNT} wildcard domains to ${WILDCARD_INPUT}"

# Subdomain Enum
if [[ "$WILDCARD_COUNT" -gt 0 ]]; then
  echo "[*] Running subfinder..."
  subfinder -silent -dL "$WILDCARD_INPUT" > "$SUBFINDER_OUTPUT"
  cat "$SUBFINDER_OUTPUT" >> "$HTTPX_INPUT"
  echo "[✓] Subfinder found $(wc -l < "$SUBFINDER_OUTPUT") subdomains."
else
  echo "[*] Skipping subfinder."
fi

# Deduplicate httpx input
sort -u "$HTTPX_INPUT" -o "$HTTPX_INPUT"

# Verify server responses
if [[ ! -s "$HTTPX_INPUT" ]]; then
  echo "[*] No targets for httpx."
  exit 0
fi

echo "[*] Running httpx..."
httpx -silent -status-code -title -tech-detect -ip \
  -timeout 10 -retries 2 -t 80 -no-color \
  -l "$HTTPX_INPUT" > "$HTTPX_OUTPUT"

echo "[✓] httpx results saved to ${HTTPX_OUTPUT}"

# Create nuclei input file for scanning script
grep -oE 'https?://[^ ]+' "$HTTPX_OUTPUT" | sort -u > "$NUCLEI_INPUT"
LIVE_COUNT=$(wc -l < "$NUCLEI_INPUT")

echo "[✓] Created nuclei input from live httpx results: ${LIVE_COUNT} targets"

# Send httpx highlights to Discord
# Check Discord API and configure what I want to see from this data
HIGHLIGHTS=$(grep -E '\[(200|401|403|500)\]' "$HTTPX_OUTPUT" | head -n 10 || true)

if [[ -n "$HIGHLIGHTS" ]]; then
  MESSAGE="🌐 **Interesting Live Hosts Found (httpx)**\n\`\`\`\n$HIGHLIGHTS\n\`\`\`"
  payload=$(jq -Rn --arg msg "$MESSAGE" '{content: $msg}')
  curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK" >/dev/null
  echo "[✓] Sent httpx highlights to Discord."
else
  echo "[*] No interesting httpx results to report."
fi

# Update all_live_urls_seen.txt
mkdir -p "$BASE_DIR"
touch "$ALL_LIVE_FILE"

cat "$NUCLEI_INPUT" "$ALL_LIVE_FILE" | sort -u > "${ALL_LIVE_FILE}.tmp"
mv "${ALL_LIVE_FILE}.tmp" "$ALL_LIVE_FILE"

echo "[✓] Updated all_live_urls_seen.txt (total: $(wc -l < "$ALL_LIVE_FILE"))"

echo "[✓] Recon complete for ${TIMESTAMP}"

