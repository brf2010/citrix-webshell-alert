# what is this
an attempt to have some alerting for compromise on Citrix systems. this code is just an alerting wrapper around NCSC-NL's "live host bash check" script. it sends the output of that script to a splunk HEC endpoint, but the script is simple enough that it could be adapted to send data via any other means.

# how2install

## install the scripts
ssh to your citrix endpoint
drop to `shell`
run these commands to drop the scripts on your netscaler node (you really should inspect these files instead of running them blindly in production, but i'm not your dad)
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
crontab -e 
*/10       *       *       *       *       sh /var/nsinstall/webshell_alert.sh '<https://<HEC ENDPOINT>:8088/services/collector/event>' '<HEC TOKEN>' 2>&1 > /tmp/script_output.txt