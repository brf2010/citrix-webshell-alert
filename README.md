# what is this
an attempt to have some alerting for compromise on Citrix systems. this code is just an alerting wrapper around [NCSC-NL's "live-host-bash-check"](https://github.com/NCSC-NL/citrix-2025/tree/main/live-host-bash-check) script. it sends the output of that script to a splunk HEC endpoint, but the script is simple enough that it could be adapted to send data via any other means.

this is not at all officially supported by citrix, but neither are their customers.

# how2install

## install the scripts
ssh to your citrix endpoint

drop to `shell`

run these commands to drop the scripts on your netscaler endpoint (you really should inspect these files instead of running them blindly in production, but i'm not your dad)
```
cd /var/nsinstall/
curl -O https://raw.githubusercontent.com/brf2010/citrix-webshell-alert/refs/heads/main/webshell_alert.sh
curl -O https://raw.githubusercontent.com/NCSC-NL/citrix-2025/refs/heads/main/live-host-bash-check/TLPCLEAR_check_script_cve-2025-6543-v1.8.sh
```
OR copy the files over with `scp`
```
host=some.netscaler.adc.corpo.domain
scp webshell_alert.sh nsroot@$host:/var/nsinstall/
scp TLPCLEAR_check_script_cve-2025-6543-v1.8.sh nsroot@$host:/var/nsinstall
```

## install crontab
from a root shell:
`crontab -e `

`*/10       *       *       *       *       sh /var/nsinstall/webshell_alert.sh 'https://<HEC ENDPOINT>:8088/services/collector/event' '<HEC TOKEN>' 2>&1 > /tmp/script_output.txt`
modify the cron timing to run at whatever interval you want

# what do i do with this now that it's in splunk
whatever you want, man, but here's a pile of SPL to pull out the relevant fields

```
index=netscaler sourcetype=citrix_webshell_checks 
| rex field=_raw "(?s)PHP files in /var/netscaler/ =====\n(?<PHP>.*?)(?:=====|$)"
| rex field=_raw "(?s)XHTML files in /var/netscaler/ =====\n(?<XHTML>.*?)\n(?:=====|$)" 
| rex field=_raw "(?s)Check for setuid shell at /var/tmp/sh =====\n(?<suid>.*?)\n\n(?:=====|$)" 
| rex field=_raw "(?s)Root-owned SUID files =====\n(?<RootSUID>.*?)\n(?:=====|$)" 
| rex field=_raw "(?s)NSPPE core dumps \(low confidence indicator\) =====\n(?<NSPPE>.*?)\n(?:=====|$)" 
| rex field=_raw "(?s)Checking rc\.netscaler for backdoor =====\n(?<rcNetscaler>.*?)\n(?:=====|$)" 
| rex field=_raw "(?s)Checking httpd configuration changes =====\n(?<httpdConfig>.*?)"
```
and a where command to only show events from systems that are returning data that's worth looking into further
```
| where PHP!="" 
    OR XHTML!="" 
    OR suid != "/var/tmp/sh does not exist or is not setuid."
    OR RootSUID!="" 
    OR NSPPE!="" 
    OR rcNetscaler!="" 
    OR httpdConfig!=""
```
stick those in an alert that runs every 10 minutes and you might know when you've been hacked