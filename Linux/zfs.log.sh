#! /bin/sh

BASEDIR=~/zfs.log
DTG=`date +%Y%m%d.%H%M%S`
RETENTION=90

/bin/cat /proc/spl/kstat/zfs/arcstats > ${CURFILE}
/bin/cat /proc/spl/kmem/slab > ${BASEDIR}/slab.${DTG}
/bin/cat /proc/slabinfo > ${BASEDIR}/slabinfo.${DTG}
/bin/find ${BASEDIR}/log.* ${BASEDIR}/slab.* ${BASEDIR}/slabinfo.* -mtime +${RETENTION} -delete
