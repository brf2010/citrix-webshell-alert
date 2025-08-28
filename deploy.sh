#!/usr/bin/expect
# automatic deployment script for citrix ADC systems. 
# there's probably a better way to do this with ansible but i'm not smart enough to figure it out

# extract CLI args, set important variables
set user [lrange $argv 0 0]
set remote_server [lrange $argv 1 1]
set remote_install_path "/var/nsinstall"
set check_script_name "TLPCLEAR_check_script_cve-2025-6543-v1.8.sh"

# get endpoint password from user
stty -echo
send_user -- "\nPassword for $user@$remote_server: "
expect_user -re "(.*)\n"
send_user "\n"
stty echo
set pass $expect_out(1,string)

# scp files
spawn scp -o ControlPath=$control_socket webshell_alert.sh $user@$remote_server:$remote_install_path/webshell_alert.sh
expect "assword:" {
                send $pass\n
                }

exit

# open SSH connection
set timeout 10
spawn ssh $user@$remote_server

while 1 {
  expect {
    # "no)?"      {send "yes\r"}
    "denied" {
#                log_file expect_msg.log
                send_log "Can't login to $remote_server. Check username and password\n";
                exit 1
             }
    "failed" {
#                log_file expect_msg.log
                send_log "Host $remote_server exists. Check ssh_hosts file\n";
                exit 3
             }
    timeout {
#                log_file expect_msg.log
                send_log "Timeout problem. Host $remote_server doesn't respond\n";
                exit 4
            }
    "refused" {
#                log_file expect_msg.log
                send_log "Host $remote_server refused to SSH.\n"
#                log_file
              }
    "assword:" {
                send $pass\n
                }
    ">"         {
                send -- "shell\n"
                break
                }
  }
}

set send_slow {10 .005}
expect "#"

# update root crontab
send -- "cat > crontab\n"
sleep 0.5

set crontabfh [open crontab r]
while {[gets $crontabfh read_line] != -1} {
        send -s "$read_line\n"
 }
close $crontabfh

send -- "\x04"
expect "#"
send "crontab crontab\n"
expect "#"
send "exit\n"
expect ">"
send "exit\n"