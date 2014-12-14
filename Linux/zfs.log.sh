#! /bin/sh

BASEDIR=~/zfs.log
DTG=`date +%Y%m%d.%H%M%S`
RETENTION=90

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
# 14-Dec-2014	Peter Ashford	Add CDDL license.
# 14-Dec-2014	Peter Ashford	Moved retention time to a variable.
# 12-Dec-2014	Peter Ashford	Created this.

/bin/cat /proc/spl/kstat/zfs/arcstats > ${CURFILE}
/bin/cat /proc/spl/kmem/slab > ${BASEDIR}/slab.${DTG}
/bin/cat /proc/slabinfo > ${BASEDIR}/slabinfo.${DTG}
/bin/find ${BASEDIR}/log.* ${BASEDIR}/slab.* ${BASEDIR}/slabinfo.* -mtime +${RETENTION} -delete
