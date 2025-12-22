#!/bin/bash

set -euo pipefail

# === Config ===
BASE_DIR="h1_scope_logs"
LOG_DIR="${BASE_DIR}/logs"
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/weekly_recon_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

{
echo "========== Weekly Recon Job Started at $(date) =========="

echo "[1] Running: Scope script"
python3 pull_private_scope.py

echo "[2] Running: Recon script"
bash private_scope_recon.sh

echo "[3] Running: Scanning script"
bash private_scope_scans.sh

# Start flask server to easily view and filter through interesting results --------->
# ------

echo "[4] Running: Full scope scans"
bash weekly_nuclei_all.sh

echo "========== Weekly Recon Job Finished at $(date) =========="

} | tee "$LOG_FILE"
