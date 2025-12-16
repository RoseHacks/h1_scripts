#!/bin/bash

set -e

mkdir -p ~/GitHub/scripts/custom_finals/h1_scope_logs/logs

echo "[*] Installing required tools and packages..."
sudo apt update
sudo apt install -y python3 python3-pip jq cron curl flask

# Other tools
export PATH="$HOME/go/bin:$PATH"
if ! command -v subfinder &> /dev/null; then
    echo "[*] Installing subfinder..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
fi

if ! command -v httpx &> /dev/null; then
    echo "[*] Installing httpx..."
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
fi

if ! command -v nuclei &> /dev/null; then
    echo "[*] Installing nuclei..."
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
fi

# Add cron job
CRON_JOB="0 9 * * 1 bash ~/GitHub/scripts/custom_finals/master_run.sh >> ~/GitHub/scripts/custom_finals/h1_scope_logs/logs/cron_output.log 2>&1"
(crontab -l 2>/dev/null | grep -v 'master_run.sh'; echo "$CRON_JOB") | crontab -

echo "[✓] Cron job added. Recon will run weekly at 9AM on Mondays."

