#! /bin/sh

#
# This is an example of a scripted creation of a ZFS pool.
#
# The pool consists of ten data disks in RAID-Z2 and two 100GB Intel
# S3700 SSDs.  Each SSD has a 16GiB partition for the log data.  The
# remainder of the SSD will be dedicated to the L2ARC.  The log
# partitions will be mirrored.
#

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
# 19-Dec-2014	Peter Ashford	Updated to align with larger pages and
#				added comments about what/why geometry
#				is changed.
# 18-Dec-2014	Peter Ashford	Created this.

#
# Create empty partition tables on the data disks
#
for i in e f g h i j k l m n
do
    echo '0,,' | sfdisk -q /dev/sd${i}
done

#
# Create the partition tables for the cache and log devices
#
# The cylinders will be block aligned with SSD pages as large as 4MB.
#
# It is necessary to change the geometry, as the default has 255 heads
# and 63 sectors per track, which aligns poorly with SSD pages.  Proper
# alignment with SSD pages is critical to good performance.
#
# The cylinder count is appropriate for the Intel 100GB S3700 SSD.
# By Intel spec, this SSD has 195371568 512-byte sectors.
#
for i in c d
do
    ( echo '1,4096,L' ; echo '4097,,L' ) | sfdisk -C 23849 -H 256 -S 32 -q /dev/sd${i}
done

zpool create -f -o ashift=12 data \
    raidz2 sde sdf sdg sdh sdi sdj sdk sdl sdm sdn \
    log mirror /dev/sdc1 /dev/sdd1 \
    cache /dev/sdc2 /dev/sdd2
