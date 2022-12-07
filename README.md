# pex_test-item_2

1. host_list.conf = Indicate hosts that have to be upgraded. Count is from 192.168.68.100-120 (I added .68. to the IP range from the challenge doc as it only indicates 3 fields instead of 4).

2. parallel_ssh.sh = Will read host_list.conf from item 1 and will loop through all the hosts listed there, running auto_upgrade.sh in the background as it goes.

3. auto_upgrade.sh = Will run the Postgres upgrade sequence thru parallel_ssh.sh.

4. terminate_longrunning_web.sh (BONUS) = Will read host_list.conf from item 1 and will loop through all the hosts listed there. The hosts will then be captured by a variable as an argument for the -h switch of psql. It will then run and kill all sessions with the user "web" that is running for more than a minute.
