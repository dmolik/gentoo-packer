#!/bin/bash

echo "= INSTALLING GENTOO ====================================================="

echo "= PARTITIONING DISKS ===================================================="
sgdisk -n 1:0:+2M -t 1:ef02 -c 1:"grub" \
	   -n 2:0:0   -t 2:8300 -c 2:"root" \
	   -p /dev/sda
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt/gentoo
cd /mnt/gentoo

echo "= UNPACKING STAGE3 ======================================================"
mv -v /tmp/stage3-amd64-nomultilib.tar.xz /mnt/gentoo
mv -v /tmp/portage-latest.tar.xz          /mnt/gentoo
tar xpf stage3-amd64-nomultilib.tar.xz
ls /mnt/gentoo

echo "= CHROOTING ============================================================="
cp --dereference /etc/resolv.conf /mnt/gentoo/etc
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys  /mnt/gentoo/sys
mount --rbind /dev  /mnt/gentoo/dev
chroot /mnt/gentoo /bin/bash

rm /etc/make.profile
ln -s /etc/portage/make.conf /etc/make.conf

echo "= UNPACKING PORTAGE ====================================================="
mkdir -p /usr/portage
ls /
mv -v /portage-latest.tar.xz /usr/portage
cd /usr/portage
tar xpf portage-latest.tar.xz
chown root:portage /usr/portage/distfiles
cd ~

echo "= UPDATING MAKE.CONF ===================================================="

echo <<EOF > /etc/portage/make.conf
CHOST="x86_64-pc-linux-gnu"

CFLAGS="-march=native -O2 -pipe"
CXXFLAGS="\${CFLAGS}"
ACCEPT_KEYWORDS="~*"

MAKEOPTS="-j4"
GRUB_PLATFORMS="coreboot pc"

LINGUAS="en en_US"
L10N="en en_US"
PYTHON_TARGETS="python2_7"
PYTHON_SINGLE_TARGET="python2_7"
POSTGRES_TARGETS="postgres10"

CPU_FLAGS_X86="avx avx2 aes mmx sse sse2 ssse3 sse4_1 sse4_2"

SYSTEM="threads jemalloc udev vim-syntax"
SYSTEM="\${SYSTEM} jit pcre pcre-jit -bindist"
SYSTEM="\${SYSTEM} uuid gmp audit"

NET="curl json ssh"
NET="\${NET} -sslv3 -sslv2"

LANGS="perl -python"
DB="lmdb"
VCS="git"

USE="\${USE} \${SYSTEM} \${AUTH} \${LANGS} \${DB} \${VCS} \${NET}"

PORTDIR="/usr/portage"
DISTDIR="\${PORTDIR}/distfiles"
PKGDIR="\${PORTDIR}/packages"
EOF

echo "= BUILDING UTILITIES ===================================================="
emerge -q -1 --jobs=4 app-portage/eix app-text/tree sys-process/lsof sys-process/htop app-editors/vim dev-vcs/git
