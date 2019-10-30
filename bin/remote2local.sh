#!/bin/bash
# SPDX-License-Identifier: GPL-3.0+
# Copyright (C) 2019, Martin Kepplinger <martink@posteo.de>
version="0.1"

# TODO detect backup in progress, and exit early

have_config_file=0
success=0
quiet=0
tries=1
vnc=0

RSYNC_SKIP_COMPRESS="3fr/3g2/3gp/3gpp/7z/aac/ace/amr/apk/appx/appxbundle"
RSYNC_SKIP_COMPRESS+="/arc/arj/arw"
RSYNC_SKIP_COMPRESS+="/asf/avi/bz2/cab/cr2/crypt[5678]/dat/dcr/deb/dmg/drc/ear"
RSYNC_SKIP_COMPRESS+="/erf/flac/flv/gif/gpg/gz/iiq/iso/jar/jp2/jpeg/jpg/k25/kdc"
RSYNC_SKIP_COMPRESS+="/lz/lzma/lzo/m4[apv]/mef/mkv/mos/mov/mp[34]/mpeg"
RSYNC_SKIP_COMPRESS+="/mp[gv]/msi"
RSYNC_SKIP_COMPRESS+="/nef/oga/ogg/ogv/opus/orf/pef/png/qt/rar/rpm/rw2/rzip/s7z"
RSYNC_SKIP_COMPRESS+="/sfx/sr2/srf/svgz/t[gb]z/tlz/txz/vob/wim/wma/wmv/xz/zip"

function usage() {
	echo "remote2local v$version"
	echo ""
	echo "$0 -c <configfile> [-q] [-r <nr_of_retries>]"
	echo "	-c	path to config file, see example for the settings"
	echo "	-q	quiet. print less"
	echo "	-r	number of retries until remote is reachable. 0 for inifitely"
	echo "	-h	print this help text"
}

args=$(getopt -o c:qr:vh -- "$@")
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
	-q)
		quiet=1
		;;
	-r)
		tries=$2
		shift
		;;
	-v)
		vnc=1
		shift
		;;
	-h)
		usage
		exit 0
		;;
        --)
		shift
                break
		;;
	*)
		echo "Invalid option: $1"
		usage
		exit 1
		;;
	esac
	shift
done

if [ "$have_config_file" -eq 0 ] ; then
	CONFIG_FILE="/usr/local/etc/remote2local.conf"
	read -r -p "continue with ${CONFIG_FILE}?"
fi

if [ ! -f ${CONFIG_FILE} ]; then
	echo -e "${RED}Error:${NC} config file not found: ${CONFIG_FILE}"
	exit 1
fi

source ${CONFIG_FILE}
if [ "${vnc}" -gt 0 ] ; then
	ssh -t -t -L 5900:localhost:5900 ${source_ssh} 'x11vnc -localhost -display :0' &
	sleep 5
	vncviewer -encodings "copyrect tight zrle hextile" localhost:0
	exit 0
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

date_started=$(date +%Y-%m-%d)
source ${CONFIG_FILE}
if [ ! $quiet -gt 0 ] ; then
	echo -e "${YELLOW}======= remote2local version $version - happy backuping ======${NC}"
fi


if [ ! -f "${EXCLUDE_LIST}" ]; then
	echo -e "${RED}Config Error:${NC} exclude file not found: ${EXCLUDE_LIST}"
	exit 1
fi

if [ -z "${archive_name}" ] ; then
	echo -e "${RED}Config Error:${NC} no archive name for local destination"
	exit 1
fi

if [ -z "${source_dir}" ] ; then
	echo -e "${RED}Config Error:${NC} no source directory for remote source"
	exit 1
fi

function user_cancel() {
	exit 0
}
trap "user_cancel" SIGINT

function trap_exit()
{
	if [ ! $quiet -gt 0 ] ; then
		echo -e "${YELLOW}======== stopping $(date) ==========${NC}"
	fi

	if [ ! $success -gt 0 ] ; then
		echo -e "remote2local ${RED}stopped${NC}."
		if [ -d "${dest_dir}" ] ; then
			echo "resetting back..."
			cd "${dest_dir}"
			rm -rf "${archive_name}"-"${date_started}"
			cd - &> /dev/null
		fi
	fi
}
trap "trap_exit" EXIT

if [ ! $quiet -gt 0 ] ; then
	echo "-------------- start rsync from ${source_ssh} ----------------"
fi

rsync_verbose=""
if [ $quiet -gt 0 ] ; then
	rsync_verbose="--human-readable --info=progress2"
else
	rsync_verbose="--verbose --human-readable --info=progress2"
fi

wait_infinitely=0
if [ "$tries" -eq 0 ] ; then
	wait_infinitely=1
	tries=1
	if [ ! $quiet -gt 0 ] ; then
		echo "waiting infinitely until remote is reachable"
	fi
fi

while [ $tries -ne 0 ] ; do
	tries=$(($tries-1))

	if [ $wait_infinitely -gt 0 ] ; then
		tries=1
	fi

	# TODO logfile in /tmp instead of /dev/null

	if [ ! -d "${dest_dir}" ] ; then
		if [ ! $quiet -gt 0 ] ; then
			echo -e "${RED}Error:${NC} destination directory not found: ${dest_dir}"
			echo "$tries retries"
		else
			printf "${RED}.${NC}"
		fi
		sleep 60
		continue
	fi
	cd "${dest_dir}"

	if [ ! $quiet -gt 0 ] ; then
		rsync -aR \
		 --delete-after \
		 --fuzzy \
		 --fuzzy \
		 ${rsync_verbose} \
		 --append-verify \
		 --compress --compress-level=9 \
		 --skip-compress=$RSYNC_SKIP_COMPRESS \
		 --exclude-from="${EXCLUDE_LIST}" \
		 --ignore-missing-args \
		 -e ssh "${source_ssh}":"${source_dir}" "${archive_name}"-"${date_started}" \
		 --link-dest="${dest_dir}/${archive_name}-last"
	else
		rsync -aR \
		 --delete-after \
		 --fuzzy \
		 --fuzzy \
		 ${rsync_verbose} \
		 --append-verify \
		 --compress --compress-level=9 \
		 --skip-compress=$RSYNC_SKIP_COMPRESS \
		 --exclude-from="${EXCLUDE_LIST}" \
		 --ignore-missing-args \
		 -e ssh "${source_ssh}":"${source_dir}" "${archive_name}"-"${date_started}" \
		 --link-dest="${dest_dir}/${archive_name}-last" 2> /dev/null
	fi
	if [ "$?" -eq "0" ] ; then
		success=1
		tries=0
		sync
		ln -nsf "${archive_name}"-"${date_started}" "${archive_name}"-last
		echo -e "${GREEN}Success.${NC} latest backup is now ${archive_name}-${date_started}"
		cd - &> /dev/null
	else
		if [ ! $quiet -gt 0 ] ; then
			echo "$tries retries"
		else
			printf "."
		fi
		cd - &> /dev/null
		sleep 60
	fi
done
