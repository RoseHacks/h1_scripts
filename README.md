## HackerOne Scripts
Automation scripts for pulling down and conducting recon on my private H1 programs using Project Discovery tools. Ran once a week and sends changes to Discord server. 

* Just setup a cron job to run whenever:
  
```
Monday @ 8:15 AM — run recon:
15 8 * * 1 /usr/bin/python3 /path/to/scope_recon.py >> /var/log/scope_recon.log 2>&1
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
