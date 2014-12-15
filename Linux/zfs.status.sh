#! /bin/sh

FLAGFILE=/etc/zfs/flag.status
MESSAGE_DAYS=4
RECIPIENTS=root@localhost

# Copyright 2014 Peter Ashford (www.accs.com).  All rights reserved. 
# 
# CDDL HEADER START 
# 
# The contents of this file are subject to the terms of the 
# Common Development and Distribution License (the "License"). 
# You may not use this file except in compliance with the License. 
# 
# You can obtain a copy of the license at docs/cddl1.txt or 
# http://opensource.org/licenses/CDDL-1.0. 
# See the License for the specific language governing permissions 
# and limitations under the License. 
# 
# When distributing Covered Code, include this CDDL HEADER in each 
# file and include the License file at docs/cddl1.txt. 
# If applicable, add the following below this CDDL HEADER, with the 
# fields enclosed by brackets "[]" replaced with your own identifying 
# information: Portions Copyright [yyyy] [name of copyright owner] 
# 
# CDDL HEADER END 
# 
# 15-Dec-2014	Peter Ashford	Created this.

# Clean up old files
find /tmp/zfs.status.* -mtime +30 -delete

/sbin/zpool status -x | /bin/grep -iv "all pools are healthy" > /tmp/zfs.status.$$
if [ $? = 1 ]
then
    if [ -f ${FLAGFILE} ]
    then
	echo From: ZFS@`hostname` > /tmp/zfs.status.$$.message
	echo To: ${RECIPIENTS} >> /tmp/zfs.status.$$.message
	echo Subject: ZFS error corrected on `hostname` >> /tmp/zfs.status.$$.message
	echo Content-Type: text/plain >> /tmp/zfs.status.$$.message

	/usr/sbin/sendmail -t < /tmp/zfs.status.$$.message
	/bin/rm -f /tmp/zfs.status.$$.message
    fi
    /bin/rm -f /tmp/zfs.status.$$ ${FLAGFILE}
    exit 0
fi

if [ -f ${FLAGFILE} ]
then
    RESULT=`/bin/find ${FLAGFILE} -mtime +${MESSAGE_DAYS}`
    if [ -n ${RESULT} ]
    then
	# Not long enough since last message
	/bin/rm -f /tmp/zfs.status.$$
   	exit
    fi
fi

/bin/touch ${FLAGFILE}

echo From: ZFS@`hostname` > /tmp/zfs.status.$$.message
echo To: ${RECIPIENTS} >> /tmp/zfs.status.$$.message
echo Subject: ZFS error on `hostname` >> /tmp/zfs.status.$$.message
echo Content-Type: text/plain >> /tmp/zfs.status.$$.message
echo >> /tmp/zfs.status.$$.message
echo ZFS error encountered >> /tmp/zfs.status.$$.message
echo >> /tmp/zfs.status.$$.message
/bin/cat /tmp/zfs.status.$$ >> /tmp/zfs.status.$$.message

/usr/sbin/sendmail -t < /tmp/zfs.status.$$.message
/bin/rm -f /tmp/zfs.status.$$ /tmp/zfs.status.$$.message
