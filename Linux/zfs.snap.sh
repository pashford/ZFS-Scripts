#! /bin/sh

# The number of daily snapshots to retain
RETAIN_DAILY=90

# The number of days to keep the hourly snapshots
#
# NOTE:  These are called 'hourly', but they can be taken at any interval.
RETAIN_HOURLY=4

# The hour that is to be saved as the daily snapshot
DAILY_HOUR=16

# Uncomment to put into debug mode
# DEBUG="echo"

#
#	Format of the snapshot name:
#
#	Column	Description
#	1-5	"Snap-"
#	6	"D" (daily) or "H" (hourly)
#	7	"."
#	8-11	Year
#	12-13	Month
#	14-15	Day
#	16	"."
#	17-18	Hour
#	19-20	Minute
#	21-22	Second

usage() {
    echo "usage $0 [-d daily-days] [-h hourly-days] [-H hourly-hour] file-system ..."
    exit
}

#
#	This function subtracts days from a date.  The code isn't pretty, but
#	neither is the Gregorian calandar.  The good news is that it uses shell
#	internals exclusively, so it's fairly fast - faster than a fork/exec.
#
back_date() {
    YEAR=${1:0:4}
    MONTH=${1:4:2}
    DAY=${1:6:2}
    DAY=$((${DAY}-${2}))
    while [ "${DAY}" -le "0" ]
    do
    	case $MONTH in
	  1)
	    YEAR=$((${YEAR}-1))
	    MONTH=12
	    DAY=$((${DAY}+31))
	    ;;
	  2)
	    # We don't worry about the century here.
	    MONTH=1
	    L_YEAR=$((${YEAR}%4))
	    if [ "${L_YEAR}" = "0" ]
	    then
	        DAY=$((${DAY}+29))
	    else
	        DAY=$((${DAY}+28))
	    fi
	    ;;
	  4|6|8|9|11)
	    MONTH=$((${MONTH}-1))
	    DAY=$((${DAY}+31))
	    ;;
	  3|5|7|10|12)
	    MONTH=$((${MONTH}-1))
	    DAY=$((${DAY}+30))
	    ;;
    	esac
    done
    if [ "${MONTH:0:1}" != "0" -a "${MONTH}" -lt "10" ]
    then
	MONTH="0${MONTH}"
    fi
    if [ "${DAY:0:1}" != "0" -a "${DAY}" -lt "10" ]
    then
	DAY="0${DAY}"
    fi
    echo ${YEAR}${MONTH}${DAY}
}

#
#	Clean up old daily snapshots
#
clean_daily() {
    SNAP_LIMIT=`back_date ${2} ${RETAIN_DAILY}`
#    echo Daily Snapshot Limit = ${SNAP_LIMIT}
    SNAPS=`echo ${SNAPSHOT_LIST} | \
	tr ' ' '\n' | \
    	/bin/grep "@Snap-D" | \
	/bin/sed -e "s/.*Snap-D.//" | \
	/bin/sort`
    for SNAPSHOT in ${SNAPS}
    do
    	SNAP_DATE=${SNAPSHOT:0:8}
	if [ ${SNAP_DATE} -le ${SNAP_LIMIT} ]
	then
	    ${DEBUG} /sbin/zfs destroy ${1}@Snap-D.${SNAPSHOT}
	else
	    break
	fi
    done
}

#
#	Make a daily snapshot
#
make_daily() {
    ${DEBUG} /sbin/zfs snapshot ${1}@Snap-D.${2}
    clean_daily ${1} ${2}
}

#
#	Clean up old hourly snapshots
#
clean_hourly() {
    SNAP_LIMIT=`back_date ${2} ${RETAIN_HOURLY}`
#    echo Hourly Snapshot Limit = ${SNAP_LIMIT}
    SNAPS=`echo ${SNAPSHOT_LIST} | \
	tr ' ' '\n' | \
    	/bin/grep "@Snap-H" | \
	/bin/sed -e "s/.*Snap-H.//" | \
	/bin/sort`
    for SNAPSHOT in ${SNAPS}
    do
    	SNAP_DATE=${SNAPSHOT:0:8}
	if [ ${SNAP_DATE} -le ${SNAP_LIMIT} ]
	then
	    ${DEBUG} /sbin/zfs destroy ${1}@Snap-H.${SNAPSHOT}
	else
	    break
	fi
    done
}

#
#	Make an hourly snapshot.  This may become a daily snapshot.
#
#	The Hourly snapshots may be taken at any time, including multiple times per hour.
#	If the previous Daily snapshot doesn't exist, create one.
#
make_hourly() {
    SNAPSHOT_LIST=`/sbin/zfs list -H -t snapshot -o name | grep "^${1}@Snap-"`

    if [ "${DTG:9:2}" = "${DAILY_HOUR}" ]
    then
	DAILY=`echo ${SNAPSHOT_LIST} | tr ' ' '\n' | grep "@Snap-D.${2:0:10}*"`
	if [ -z "${DAILY}" ]
	then
	    make_daily ${1} ${2}
	    return
	fi

    # check for missed Daily snapshot today
    elif [ "${DTG:9:2}" -gt "${DAILY_HOUR}" ]
    then
	DAILY=`echo ${SNAPSHOT_LIST} | tr ' ' '\n' | grep "Snap-D.${DTG:0:7}"`
	if [ -z "${DAILY}" ]
	then
	    make_daily ${1} ${2}
	    return
	fi
    # check for missed Daily snapshot yesterday
    else
    	YESTERDAY=`back_date ${DTG:0:8} 1`
	DAILY=`echo ${SNAPSHOT_LIST} | tr ' ' '\n' | grep "Snap-D.${YESTERDAY}"`
	if [ -z "${DAILY}" ]
	then
	    # If there are more then one daily snapshots yesterday, assume it's OK.
	    SNAPS=`echo ${DAILYS} | wc -w`
	    if [ ${SNAPS} -gt 1 ]
	    then
		continue
	    fi
	    if [ ${SNAPS} -gt 1 ]
	    then
		SNAP_HOUR=`echo ${DAILY} | cut -d '@' -f 2`
		SNAP_HOUR=${SNAP_HOUR:16:2}
	    else
	    	SNAP_HOUR=0
	    fi
	    if [ ${SNAP_HOUR} -lt ${DAILY_HOUR} ]
	    then
		make_daily ${1} ${2}
		return
	    fi
	fi
    fi

    ${DEBUG} /sbin/zfs snapshot ${1}@Snap-H.${2}
    clean_hourly ${1} ${2}
}

if [ -z "$1" ]
then
    usage
fi

# convert to 'getopts'

DONE=0
while [ ${DONE} = 0 ]
do
    case $1 in
      -d)
	if [ "$2" = "" ]
	then
	    usage
	fi
	RETAIN_DAILY=$2
	shift ; shift
	;;
      -h)
	if [ "$2" = "" ]
	then
	    usage
	fi
	RETAIN_HOURLY=$2
	shift ; shift
	;;
      -H)
	if [ "$2" = "" ]
	then
	    usage
	fi
	DAILY_HOUR=$2
	shift ; shift
	;;
      *)
	DONE=1
	;;
    esac
done

if [ "$1" = "" ]
then
    usage
fi

/sbin/zfs list -H -o name > /tmp/$$.zfs.fs

DO_USAGE=0
DTG=`date +%Y%m%d.%H%M%S`
while [ "$1" != "" ]
do
    /bin/grep "^${1}\$" /tmp/$$.zfs.fs > /dev/null
    if [ "$?" = "1" ]
    then
    	DO_USAGE=1
	echo "Invalid file-system name - '${1}'"
	shift
	continue
    fi
    make_hourly ${1} ${DTG}
    shift
done

rm -f /tmp/$$.zfs.fs

if [ "${DO_USAGE}" = "1" ]
then
    usage
fi
