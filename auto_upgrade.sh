#!/bin/bash

data_dir=/local/pgsql/        ##Change accordingly based on directory ABOVE Postgres data directories
log_dir=/local/pgsql/log        ##Change accordingly based on directory where script logs can be dumped 
old_pg_version=12       ##Change value as per old version
new_pg_version=14       ##Change value as per new version
backup_dir=/local/pgsql/backup    ##Directory where conf and DB backups will be dumped before upgrade proper
old_data_dir=/local/pgsql/data    ##Data directory of current version
new_data_dir=/local/pgsql/data_${new_pg_version}    ##Data directory of the upgraded version

cp -p ${old_data_dir}/*.conf ${backup_dir}/             ##Backup config files

##Backup all DBs except templates
for db_list in `psql -t -c "select datname from pg_database where not datistemplate" | grep '\S' | awk '{$1=$1};1'`; do
   pg_dump -Fc -f ${backup_dir}/${db_list}_backup.dmp ${db_list}
done

pg_dumpall -v --globals-only -f ${backup_dir}/globals-only.sql    ##Backup globals


printf '%s\n' y y | yum install postgresql${new_pg_version}*      ##Automatically confirm prompts when installing desired Postgres version

/usr/pgsql-${new_pg_version}/bin/initdb /local/pgsql/data_${new_pg_version}      ##Initialize data directory of new Postgres version

check_result=`/usr/pgsql-${new_pg_version}/bin/pg_upgrade --old-bindir=/usr/pgsql-${old_pg_version}/bin/ --new-bindir=/usr/pgsql-${new_pg_version}/bin/ --old-datadir=${old_data_dir}/ --new-datadir=${new_data_dir}/ --check | tail`     ##Check if pre-requisites are met before pg_upgrade run

##Proceed with pg_upgrade if old and new Postgres instances are compatible, if not, print message regarding failure
if [ ${check_result} == "*Clusters are compatible*" ]
then
        /usr/pgsql-${old_pg_version}/bin/pg_ctl -D ${old_data_dir} stop    ##Stop old running instance
        /usr/pgsql-${new_pg_version}/bin/pg_upgrade --old-bindir=/usr/pgsql-${old_pg_version}/bin/ --new-bindir=/usr/pgsql-${new_pg_version}/bin/ --old-datadir=${old_data_dir}/ --new-datadir=${new_data_dir}/ > ${log_dir}/pg_upgrade_prereq.log       ##Start pg_upgrade run proper
        ##Check if upgrade is successful, if not, print message regarding failure
        if grep "Upgrade Complete" ${log_dir}/pg_upgrade_prereq.log
        then
                /usr/pgsql-${new_pg_version}/bin/pg_ctl -D ${new_data_dir} start    ##Start new Postgres instance
                /usr/pgsql-${new_pg_version}/bin/psql -c "SELECT now() - pg_postmaster_start_time() as uptime;" > ${log_dir}/pg_upgrade_prereq.log    ##Do a test check if instance is up and running and accepting connections
                ##Check if DB is up and running and accepting connections, if not, check system logs on the data directory
                if grep "uptime" ${log_dir}/pg_upgrade_prereq.log
                then
                        echo "DB is upgraded and up and running..."
                else
                        echo "Check system logs..."
                fi
        else
                cat ${log_dir}/pg_upgrade_prereq.log
        fi
else
        /usr/pgsql-${new_pg_version}/bin/pg_upgrade --old-bindir=/usr/pgsql-${old_pg_version}/bin/ --new-bindir=/usr/pgsql-${new_pg_version}/bin/ --old-datadir=${old_data_dir}/ --new-datadir=${new_data_dir}/ --check > ${log_dir}/pg_upgrade_fail.log
        cat ${log_dir}/pg_upgrade_fail.log
fi
