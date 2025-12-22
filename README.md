## HackerOne Scripts
Automation scripts for pulling down my private H1 program scopes and conducting weekly recon and scanning using Project Discovery tools. Ran once a week and sends updates to Discord server. 

```
ubuntu@dev$: ./master_run.sh

```
* Just setup a cron job to run whenever:
  
```
Monday @ 8:15 AM — run recon:
15 8 * * 1 /usr/bin/bash /path/to/master_run.sh >> /var/log/scope_recon.log 2>&1
```

### Notes
* Make sure you set the variables for $h1_username $h1_api_token $discord_server.
* Scripts parse program results for private programs by doing a negative grep for public_mode. Important to change if you want all the programs.
* Modify recon commands based on needs and configure API tokens for PD tools.

### To Do 
* Create a dashboard. Create a tags page to sort by tech stacks.
* Renew Subfinder results every week as well.
* Implment screenshots with httpx to include in the dashboard view.

### Resources
* [HackerOne API](https://api.hackerone.com/)
* [Project Discovery GitHub](https://github.com/projectdiscovery)
* [Discord Webhooks](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
