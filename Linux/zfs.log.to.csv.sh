#! /bin/sh

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
# 14-Dec-2014	Peter Ashford	Created this.

if [ "$1" != "" ]
then
    cd $1
    FILE=../$1
else
    FILE=current
fi

/bin/rm -f ${FILE}.arcstats.csv ${FILE}.slab.csv

# ARCSTAT DATA

# Create the header
echo -n 'Parameter,' > ${FILE}.arcstats.csv
/bin/ls log.* | \
    /bin/sed -e 's/^log.//' \
	-e 's/\(....\)\(..\)\(..\).\(..\)\(..\)\(..\)/\1-\2-\3 \4:\5:\6/' | \
    /usr/bin/tr '\n' ',' | \
    /bin/sed -e 's/,$//' >> ${FILE}.arcstats.csv
echo >> ${FILE}.arcstats.csv

TEMP=`/bin/ls log.* | /usr/bin/head -1`
VARS=`/bin/sed -e '1,2 d' -e 's/ .*//' ${TEMP}`
for ATTRIBUTE in $VARS
do
    echo -n "${ATTRIBUTE}," >> ${FILE}.arcstats.csv
    /bin/grep "^${ATTRIBUTE} " log.* | \
	/bin/sed -e 's/.* //' | \
	/usr/bin/tr '\n' ',' | \
	/bin/sed -e 's/,$//' >> ${FILE}.arcstats.csv
    echo >> ${FILE}.arcstats.csv
done

# SLAB DATA

# Create the header
echo -n 'Parameter,' > ${FILE}.slab.csv
/bin/ls slab.* | \
    /bin/sed -e 's/^slab.//' \
	-e 's/\(....\)\(..\)\(..\).\(..\)\(..\)\(..\)/\1-\2-\3 \4:\5:\6/' | \
    /usr/bin/tr '\n' ',' | \
    /bin/sed -e 's/,$//' >> ${FILE}.slab.csv
echo >> ${FILE}.slab.csv

TEMP=`/bin/ls slab.* | /usr/bin/head -1`
VARS=`/bin/sed -e '1,2 d' -e 's/ .*//' ${TEMP}`
for ATTRIBUTE in $VARS
do
    /bin/grep "^${ATTRIBUTE} " slab.* | \
	/bin/sed -e 's/   */ /g' \
	    -e 's/[^ ]* //' > /tmp/slab.$$
    FIELD=2
    for PARAM in size alloc slabsize objsize slab_total slab_alloc slab_max object_total object_alloc object_max emerg_dlock emerg_alloc emerg_max
    do
    	echo -n "${ATTRIBUTE}-${PARAM}," >> ${FILE}.slab.csv
	/bin/cut -d " " -f ${FIELD} /tmp/slab.$$ | \
	    /usr/bin/tr '\n' ',' | \
	    /bin/sed -e 's/,$//' >> ${FILE}.slab.csv
	echo >> ${FILE}.slab.csv
	FIELD=$((${FIELD}+1))
    done
done

# Create the header
echo -n 'Parameter,' > ${FILE}.slabinfo.csv
/bin/ls slabinfo.* | \
    /bin/sed -e 's/^slabinfo.//' \
	-e 's/\(....\)\(..\)\(..\).\(..\)\(..\)\(..\)/\1-\2-\3 \4:\5:\6/' | \
    /usr/bin/tr '\n' ',' | \
    /bin/sed -e 's/,$//' >> ${FILE}.slabinfo.csv
echo >> ${FILE}.slabinfo.csv

TEMP=`/bin/ls slabinfo.* | /usr/bin/head -1`
VARS=`/bin/sed -e '1,2 d' -e 's/ .*//' ${TEMP}`
for ATTRIBUTE in $VARS
do
    /bin/grep "^${ATTRIBUTE} " slabinfo.* | \
	/bin/sed -e 's/   */ /g' \
	    -e 's/[^ ]* //' > /tmp/slab.$$
    FIELD=1
    for PARAM in active_objs num_objs obj_size obj_per_slab pages_per_slab null null limit batch_bount shared_factor null null active_slabs num_slabs shared_avail
    do
	if [ ${PARAM} = null ]
	then
	    FIELD=$((${FIELD}+1))
	    continue
	fi
    	echo -n "${ATTRIBUTE}-${PARAM}," >> ${FILE}.slabinfo.csv
	/bin/cut -d " " -f ${FIELD} /tmp/slab.$$ | \
	    /usr/bin/tr '\n' ',' | \
	    /bin/sed -e 's/,$//' >> ${FILE}.slabinfo.csv
	echo >> ${FILE}.slabinfo.csv
	FIELD=$((${FIELD}+1))
    done
done

rm /tmp/slab.$$
