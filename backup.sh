#!/bin/bash
# SPDX-License-Identifier: GPL-3.0+
# Copyright (C) 2019, Martin Kepplinger <martink@posteo.de>

# TODO resume instead of reset

have_config_file=0

args=$(getopt -o c: -- "$@")
if [ $? -ne 0 ] ; then
        exit 1
fi
eval set -- "$args"
while [ $# -gt 0 ]
do
        case "$1" in
        -c)
                CONFIG_FILE=$2
                have_config_file=1
                shift
                ;;
        --)
                shift
                break
                ;;
        *)
                echo "Invalid option: $1"
                exit 1
                ;;
        esac
        shift
done

if [ "$have_config_file" -gt 0 ] ; then
	echo "Using configuration ${CONFIG_FILE}"
else
	echo "Please add -c <configfile>"
	exit 1
fi

if [ ! -f ${CONFIG_FILE} ]; then
	echo "config file not found!"
	exit 0
fi

source ${CONFIG_FILE}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

date_started=$(date +%Y-%m-%d)

if [ -d "${dest_dir}" ] ; then
	cd ${dest_dir}
else
	echo "destination directory not found!"
	exit 0
fi

function trap_exit()
{
	echo -e "${RED}Error${NC} while running rsync. resetting back..."
	rm -rf ${archive_name}-${date_started}
}
trap "trap_exit" EXIT

rsync -aR \
 --delete-after \
 --fuzzy \
 --fuzzy \
 --verbose --human-readable --info=progress2 \
 --compress --compress-level=9 \
 --exclude-from="${EXCLUDE_LIST}" \
 --ignore-missing-args \
 -e ssh ${source_ssh}:${source_dir} ${archive_name}-${date_started} \
 --link-dest="${dest_dir}/${archive_name}-last"

date
if [ "$?" -eq "0" ] ; then
	sync
	ln -nsf ${archive_name}-${date_started} ${archive_name}-last
	echo -e "${GREEN}Success.${NC} latest backup is now ${archive_name}-${date_started}"
else
	trap_exit
fi
