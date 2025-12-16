from flask import Flask, render_template
import os
import json
from glob import glob
from datetime import datetime

app = Flask(__name__)
BASE_DIR = "h1_scope_logs"

def get_latest_file(pattern):
    files = sorted(glob(os.path.join(BASE_DIR, pattern)), reverse=True)
    return files[0] if files else None

def parse_nuclei(file_path):
    findings = []
    with open(file_path, 'r') as f:
        for line in f:
            try:
                data = json.loads(line)
                findings.append({
                    "severity": data.get("info", {}).get("severity", "unknown").lower(),
                    "template": data.get("templateID", "unknown"),
                    "url": data.get("matched", "")
                })
            except:
                continue
    return findings

def parse_httpx(file_path):
    entries = []
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            parts = line.split()
            url = next((p for p in parts if p.startswith("http")), None)
            entries.append({
                "url": url or "unknown",
                "meta": " ".join(p for p in parts if p != url)
            })
    return entries

@app.route("/")
def dashboard():
    new_domains = []
    live_urls = []

    if (nd_file := get_latest_file("new_domains_found_*.txt")):
        with open(nd_file) as f:
            new_domains = [line.strip() for line in f if line.strip()]

    if os.path.exists(f"{BASE_DIR}/all_live_urls_seen.txt"):
        with open(f"{BASE_DIR}/all_live_urls_seen.txt") as f:
            live_urls = [line.strip() for line in f if line.strip()]

    httpx_results = parse_httpx(get_latest_file("httpx_results_*.txt") or "")
    nuclei_findings = parse_nuclei(get_latest_file("nuclei_results_*.json") or "")

    return render_template("dashboard.html",
        timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        new_domains=new_domains,
        live_urls=live_urls,
        httpx=httpx_results,
        nuclei=nuclei_findings
    )

if __name__ == "__main__":
    app.run(debug=True, port=5000)

