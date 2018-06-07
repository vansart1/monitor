This program monitors a Mac server and sends alerts if necessary

It features a smart monitoring system that only sends notifications when a 
certain threshold has been reached. This greatly minimizes the amount of 
notifications sent.
The tool also has "memory" which incorporate the previous server state into
the notification threshold.

This tool monitors:

1) CPU usage
2) RAM usage
3) Disk space on main filesystem
4) Disk space on attached drives
5) RAID status



To install:

1) cp monitor.sh /usr/local/bin/monitor
2) cp monitor.conf /usr/local/etc/monitor/monitor.conf
3) cp myemail.py /usr/local/bin/myemail
4) cp myemail_conf.ini /usr/local/etc/myemail_conf.ini
5) cp keep_alive.sh /usr/local/bin/keep_alive
6) Add to crontab "@reboot /usr/local/bin/monitor > /dev/null
7) Add to crontab "0 */1 * * * /usr/local/bin/keep_alive /usr/local/bin/monitor

