
gentoo:
	[[ -d files ]] || mkdir  files
	scripts/download.sh
	packer build gentoo-virtualbox.json
