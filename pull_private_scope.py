import requests as req
import os
from datetime import datetime

username = "<username>"
api_token = "<token>"
discord_webhook = "<link>"

output_dir = "h1_scope_logs"
os.makedirs(output_dir, exist_ok=True)

# Timestamp for file name schema
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

# File paths (timestamped of course)
private_programs_file = os.path.join(output_dir, f"private_programs_{timestamp}.txt")
scope_file = os.path.join(output_dir, f"scope_{timestamp}.txt")
wildcard_file = os.path.join(output_dir, f"scope_wildcards_{timestamp}.txt")
new_domains_file = os.path.join(output_dir, f"new_domains_found_{timestamp}.txt")

# Path to cumulative domain store. The idea is that We have a running list of all domains and add the new ones as they are found
all_domains_master_file = os.path.join(output_dir, "all_domains_seen.txt")

private_handles = set()
all_domains = set()
wildcard_domains = set()

url = "https://api.hackerone.com/v1/hackers/programs?page[size]=100"
page = 1

while url:
    print(f"[*] Scraping program list page: {page}")
    res = req.get(url, auth=(username, api_token))
    if res.status_code != 200:
        print(f"[!] Error fetching programs: {res.status_code}")
        break

    data = res.json()

    for program in data.get("data", []):
        attrs = program.get("attributes", {})
        state = attrs.get("state")
        handle = attrs.get("handle")
        if state != "public_mode" and handle:
            private_handles.add(handle)

    url = data.get("links", {}).get("next")
    page += 1

# Save program handles
with open(private_programs_file, "w") as f:
    for handle in sorted(private_handles):
        f.write(handle + "\n")

# Grab the scope from our private programs

for handle in sorted(private_handles):
    print(f"[*] Fetching scope for: {handle}")
    scope_url = f"https://api.hackerone.com/v1/hackers/programs/{handle}/structured_scopes"
    res = req.get(scope_url, auth=(username, api_token))

    if res.status_code != 200:
        print(f"[!] Failed to get scope for {handle}: {res.status_code}")
        continue

    scopes = res.json().get("data", [])

    for item in scopes:
        attrs = item.get("attributes", {})
        asset_type = attrs.get("asset_type", "")
        asset = attrs.get("asset_identifier", "").strip()
        in_scope = attrs.get("eligible_for_submission", False)

        if in_scope and asset_type in ["DOMAIN", "URL", "WILDCARD"]:
            all_domains.add(asset)
            if asset.startswith("*."):
                wildcard_domains.add(asset)

# "W"rite our scope to files 
with open(scope_file, "w") as f:
    for domain in sorted(all_domains):
        f.write(domain + "\n")

with open(wildcard_file, "w") as f:
    for domain in sorted(wildcard_domains):
        f.write(domain + "\n")

print(f"[✓] Saved scope files for {len(all_domains)} domains.")

# Detect New Domains

# Load previous domains IF the file exists
old_domains = set()
if os.path.exists(all_domains_master_file):
    with open(all_domains_master_file, "r") as f:
        old_domains = set(line.strip() for line in f)

# Find new domains
new_domains = sorted(all_domains - old_domains)

if new_domains:
    print(f"[+] Found {len(new_domains)} new domains!")
    with open(new_domains_file, "w") as f:
        for domain in new_domains:
            f.write(domain + "\n")

    # Update master domain store == running list
    with open(all_domains_master_file, "a") as f:
        for domain in new_domains:
            f.write(domain + "\n")

    # Send my Discord notification
    discord_payload = {
        "content": f"📡 **New HackerOne domains discovered** ({len(new_domains)}):\n" +
                   "```\n" + "\n".join(new_domains[:20]) + "\n```"
    }
    r = req.post(discord_webhook, json=discord_payload)

    if r.status_code == 204:
        print("[✓] Discord notification sent.")
    else:
        print(f"[!] Failed to send to Discord: {r.status_code}")
else:
    print("[*] No new domains found. No Discord alert sent.")

