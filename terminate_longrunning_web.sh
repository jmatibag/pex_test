#!/bin/bash

script_dir=/local/pgsql         ##Change accordingly based on env
host_list=${script_dir}/host_list.conf          ##Will point to file with list of hosts

##Will feed list of hosts into while loop and run the PSQL command on all hosts to kill all session that are running for more than 1 minute with the user "web"
while read p;
do
psql -h ${p} -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'web' AND (now() - pg_stat_activity.query_start) > interval '60 seconds';"
done <${host_list}
