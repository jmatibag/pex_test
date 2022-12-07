#!/bin/bash

script_dir=/local/pgsql         ##Change accordingly based on env
host_list=${script_dir}/host_list.conf          ##Will point to file with list of hosts

##Will feed list of hosts into while loop and run auto_upgrade.sh which holds the automated upgrade script
while read p;
do
sshpass -vvv -p 1qaz@WSX ssh postgres@${host_list} 'bash -s' < ${script_dir}/auto_upgrade.sh &
done <${host_list}
