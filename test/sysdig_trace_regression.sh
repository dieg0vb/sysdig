#!/bin/bash
set -eu

SCRIPT=$(readlink -f $0)
BASEDIR=$(dirname $SCRIPT)

SYSDIG=$1
CHISELS=$2
TMPBASE=${4:-$(mktemp -d --tmpdir sysdig.XXXXXXXXXX)}
TRACEDIR="${TMPBASE}/traces"
RESULTDIR="${TMPBASE}/results"
BASELINEDIR="${TMPBASE}/baseline"
BRANCH=$3

if [ ! -d "$TRACEDIR" ]; then
	mkdir -p $TRACEDIR
	cd $TRACEDIR
	wget https://s3.amazonaws.com/download.draios.com/sysdig-tests/traces.zip
	unzip traces.zip
	rm -rf traces.zip
	cd -
fi

if [ ! -d "$BASELINEDIR" ]; then
	mkdir -p $BASELINEDIR
	cd $BASELINEDIR
	wget -O baseline.zip https://s3.amazonaws.com/download.draios.com/sysdig-tests/baseline-$BRANCH.zip || wget -O baseline.zip https://s3.amazonaws.com/download.draios.com/sysdig-tests/baseline-dev.zip
	unzip baseline.zip
	rm -rf baseline.zip
	cd -
fi

echo "Executing sysdig tests in ${TMPBASE}"

ret=0

# Fields
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-n 1000" $TRACEDIR $RESULTDIR/default $BASELINEDIR/default || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-n 1000 -pc" $TRACEDIR $RESULTDIR/containers $BASELINEDIR/containers || ret=1
# Category: CPU Usage
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopcontainers_cpu" $TRACEDIR $RESULTDIR/topcontainers_cpu $BASELINEDIR/topcontainers_cpu || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopprocs_cpu" $TRACEDIR $RESULTDIR/topprocs_cpu $BASELINEDIR/topprocs_cpu || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -ctopprocs_cpu" $TRACEDIR $RESULTDIR/topprocs_cpu_container $BASELINEDIR/topprocs_cpu_container || ret=1
# Category: Errors
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopcontainers_error" $TRACEDIR $RESULTDIR/topcontainers_error $BASELINEDIR/topcontainers_error || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopfiles_errors" $TRACEDIR $RESULTDIR/topfiles_errors $BASELINEDIR/topfiles_errors || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -ctopfiles_errors" $TRACEDIR $RESULTDIR/topfiles_errors_container $BASELINEDIR/topfiles_errors_container || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopprocs_errors" $TRACEDIR $RESULTDIR/topprocs_errors $BASELINEDIR/topprocs_errors || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -ctopprocs_errors" $TRACEDIR $RESULTDIR/topprocs_errors_container $BASELINEDIR/topprocs_errors_container || ret=1
# Category: I/O
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cecho_fds" $TRACEDIR $RESULTDIR/echo_fds $BASELINEDIR/echo_fds || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -cecho_fds" $TRACEDIR $RESULTDIR/echo_fds_container $BASELINEDIR/echo_fds_container || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cfdbytes_by fd.name" $TRACEDIR $RESULTDIR/fdbytes_by $BASELINEDIR/fdbytes_by || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cfdcount_by fd.name" $TRACEDIR $RESULTDIR/fdcount_by $BASELINEDIR/fdcount_by || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ciobytes" $TRACEDIR $RESULTDIR/iobytes $BASELINEDIR/iobytes || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ciobytes_file" $TRACEDIR $RESULTDIR/iobytes_file $BASELINEDIR/iobytes_file || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cspy_file" $TRACEDIR $RESULTDIR/spy_file $BASELINEDIR/spy_file || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cstderr" $TRACEDIR $RESULTDIR/stderr $BASELINEDIR/stderr || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -cstderr" $TRACEDIR $RESULTDIR/stderr_container $BASELINEDIR/stderr_container || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cstdin" $TRACEDIR $RESULTDIR/stdin $BASELINEDIR/stdin || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cstdout" $TRACEDIR $RESULTDIR/stdout $BASELINEDIR/stdout || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -ctopcontainers_file" $TRACEDIR $RESULTDIR/topcontainers_file $BASELINEDIR/topcontainers_file || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopfiles_bytes" $TRACEDIR $RESULTDIR/topfiles_bytes $BASELINEDIR/topfiles_bytes || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -ctopfiles_bytes" $TRACEDIR $RESULTDIR/topfiles_bytes_container $BASELINEDIR/topfiles_bytes_container || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopfiles_time" $TRACEDIR $RESULTDIR/topfiles_time $BASELINEDIR/topfiles_time || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -ctopfiles_time" $TRACEDIR $RESULTDIR/topfiles_time_container $BASELINEDIR/topfiles_time_container || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopprocs_file" $TRACEDIR $RESULTDIR/topprocs_file $BASELINEDIR/topprocs_file || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -ctopprocs_file" $TRACEDIR $RESULTDIR/topprocs_file_container $BASELINEDIR/topprocs_file_container || ret=1
# Category: Logs
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cspy_logs" $TRACEDIR $RESULTDIR/spy_logs $BASELINEDIR/spy_logs || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -cspy_logs" $TRACEDIR $RESULTDIR/spy_logs_container $BASELINEDIR/spy_logs_container || ret=1
# Category: Net
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ciobytes_net" $TRACEDIR $RESULTDIR/iobytes_net $BASELINEDIR/iobytes_net || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cspy_ip 127.0.0.1" $TRACEDIR $RESULTDIR/spy_ip $BASELINEDIR/spy_ip || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cspy_port 80" $TRACEDIR $RESULTDIR/spy_port $BASELINEDIR/spy_port || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopconns" $TRACEDIR $RESULTDIR/topconns $BASELINEDIR/topconns || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -ctopconns" $TRACEDIR $RESULTDIR/topconns_container $BASELINEDIR/topconns_container || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopcontainers_net" $TRACEDIR $RESULTDIR/topcontainers_net $BASELINEDIR/topcontainers_net || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopports_server" $TRACEDIR $RESULTDIR/topports_server $BASELINEDIR/topports_server || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopprocs_net" $TRACEDIR $RESULTDIR/topprocs_net $BASELINEDIR/topprocs_net || ret=1
# Category: Performance
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cbottlenecks" $TRACEDIR $RESULTDIR/bottlenecks $BASELINEDIR/bottlenecks || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cfileslower 1000" $TRACEDIR $RESULTDIR/fileslower $BASELINEDIR/fileslower || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cnetlower 10" $TRACEDIR $RESULTDIR/netlower $BASELINEDIR/netlower || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cproc_exec_time" $TRACEDIR $RESULTDIR/proc_exec_time $BASELINEDIR/proc_exec_time || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cscallslower 1000" $TRACEDIR $RESULTDIR/scallslower $BASELINEDIR/scallslower || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopscalls" $TRACEDIR $RESULTDIR/topscalls $BASELINEDIR/topscalls || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-ctopscalls_time" $TRACEDIR $RESULTDIR/topscalls_time $BASELINEDIR/topscalls_time || ret=1
# Category: Security
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-clist_login_shells" $TRACEDIR $RESULTDIR/list_login_shells $BASELINEDIR/list_login_shells || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cspy_users" $TRACEDIR $RESULTDIR/spy_users $BASELINEDIR/spy_users || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-pc -cspy_users" $TRACEDIR $RESULTDIR/spy_users_container $BASELINEDIR/spy_users_container || ret=1
# Category: System State
# $BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-clscontainers" $TRACEDIR $RESULTDIR/lscontainers $BASELINEDIR/lscontainers || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-clsof" $TRACEDIR $RESULTDIR/lsof $BASELINEDIR/lsof || ret=1
# $BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cnetstat" $TRACEDIR $RESULTDIR/netstat $BASELINEDIR/netstat || ret=1
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-cps" $TRACEDIR $RESULTDIR/ps $BASELINEDIR/ps || ret=1
# JSON
$BASEDIR/sysdig_batch_parser.sh $SYSDIG $CHISELS "-j -n 10000" $TRACEDIR $RESULTDIR/fd_fields_json $BASELINEDIR/fd_fields_json || ret=1

rm -rf "${TMPBASE}"
exit $ret