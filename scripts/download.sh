#!/bin/bash


URL="http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-nomultilib.txt"
BASE=${URL%/*}
LATEST=$(curl ${URL})
ARCHIVE=$(echo ${LATEST##\#*\#}|awk '{print $2}')

[[ -f files/portage-latest.tar.xz ]] || \
	curl -L http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz -o files/portage-latest.tar.xz
[[ -f files/stage3-amd64-nomultilib.tar.xz ]] || \
	curl -L ${BASE}/${ARCHIVE} -o files/stage3-amd64-nomultilib.tar.xz
