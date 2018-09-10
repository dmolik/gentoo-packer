#!/bin/bash


URL="http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-nomultilib.txt"
BASE=${URL%/*}
LATEST=$(curl ${URL})
ARCHIVE=$(echo ${LATEST##\#*\#}|awk '{print $2}')

portage_age=$(echo "$(date '+%s') - $(stat -c '%Y' files/portage-latest.tar.xz )" | bc)
if [[ ! -f files/portage-latest.tar.xz ]] || (( $portage_age > 86400 )) ; then
	curl -L http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz -o files/portage-latest.tar.xz
fi
[[ -f files/stage3-amd64-nomultilib.tar.xz ]] || \
	curl -L ${BASE}/${ARCHIVE} -o files/stage3-amd64-nomultilib.tar.xz
