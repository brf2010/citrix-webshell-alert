# what is this
an attempt to have some alerting for compromise on Citrix systems. this code is just an alerting wrapper around [NCSC-NL's "live-host-bash-check"](https://github.com/NCSC-NL/citrix-2025/tree/main/live-host-bash-check) script. it sends the output of that script to a splunk HEC endpoint, but the script is simple enough that it could be adapted to send data via any other means.

this is not at all officially supported by citrix, but neither are their customers.

# how2install
## automagically
the easiest way to do this across several hosts is with the deploy.exp script. call it like this:

```./deploy.exp username some.netscaler.adc.fqdn```

PREREQUISITES:
1. take some time to read the script. seriously, don't run random shit from the internet against production. if you're not willing to do that, you should follow the manual steps below.
2. tcl expect installed and available
3. already downloaded the NCSC-NL check script into the directory you'll be running it from
4. update the crontab file with your SPLUNK_SERVER and HEC_TOKEN

the script automatically does everything the manual steps do below, so it's convenient if you need to deploy it across more than a couple ADC systems, or automate this for any reason. there's probably a way to do this with ansible instead of expect but i couldn't figure out how to get ansible to just write "shell\n" to escape the ADC CLI and get to a regular shell. if you know how to do this please contact me.

## manually
#### install the scripts
ssh to your citrix ADC

drop to `shell`

run these commands to drop the scripts on your netscaler endpoint (you really should inspect these files instead of running them blindly in production, but i'm not your dad)
```
cd /var/nsinstall/
curl -O https://raw.githubusercontent.com/brf2010/citrix-webshell-alert/refs/heads/main/webshell_alert.sh
curl -O https://raw.githubusercontent.com/NCSC-NL/citrix-2025/refs/heads/main/live-host-bash-check/TLPCLEAR_check_script_cve-2025-6543-v1.8.sh
```
OR copy the files over with `scp`
```
host=some.netscaler.adc.fqdn
scp webshell_alert.sh nsroot@$host:/var/nsinstall/
scp TLPCLEAR_check_script_cve-2025-6543-v1.8.sh nsroot@$host:/var/nsinstall
```

#### install crontab
from the same root shell:

`crontab -e `

add the following line, updating the <SPLUNK_SERVER> and <HEC_TOKEN> to values that make sense for your environment.

`*/10       *       *       *       *       sh /var/nsinstall/webshell_alert.sh 'https://<SPLUNK_SEVER>:8088/services/collector/event' '<HEC_TOKEN>' 2>&1 > /tmp/script_output.txt`

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