#!/bin/bash

echo "= INSTALLING GENTOO ====================================================="

echo "= PARTITIONING DISKS ===================================================="
sgdisk -n 1:0:+2M -t 1:ef02 -c 1:"grub" \
	   -n 2:0:0   -t 2:8300 -c 2:"root" \
	   -p /dev/sda
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt/gentoo


echo "= UNPACKING ARCHIVES ===================================================="
echo "  unpacking stage"
tar xpf /tmp/stage3-amd64-nomultilib.tar.xz -C /mnt/gentoo
echo "  unpacking portage"
tar xpf /tmp/portage-lastest.tar.xz         -C /mnt/gentoo/usr

echo "= CHROOTING ============================================================="
cd /mnt/gentoo
cp --dereference /etc/resolv.conf /mnt/gentoo/etc
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys  /mnt/gentoo/sys
mount --rbind /dev  /mnt/gentoo/dev
#chroot /mnt/gentoo /bin/bash

echo "= UPDATING MAKE.CONF ===================================================="

cat <<<'
CHOST="x86_64-pc-linux-gnu"

CFLAGS="-march=native -O2 -pipe"
CXXFLAGS="${CFLAGS}"
ACCEPT_KEYWORDS="~*"

MAKEOPTS="-j4"

LINGUAS="en en_US"
L10N="en en_US"
PYTHON_TARGETS="python2_7 python3_6"
PYTHON_SINGLE_TARGET="python3_6"
POSTGRES_TARGETS="postgres10"

CPU_FLAGS_X86="avx avx2 aes mmx sse sse2 ssse3 sse4_1 sse4_2"

SYSTEM="threads jemalloc udev vim-syntax"
SYSTEM="${SYSTEM} jit pcre pcre-jit -bindist"
SYSTEM="${SYSTEM} uuid gmp audit"
AUTH=""
NET="curl json"
NET="${NET} -sslv3 -sslv2"

LANGS="perl -python"
DB="lmdb"
VCS="git"

USE="${USE} ${SYSTEM} ${AUTH} ${LANGS} ${DB} ${VCS} ${NET}"

PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
' > /mnt/gentoo/etc/portage/make.conf

echo "= BUILDING UTILITIES ===================================================="
chroot /mnt/gentoo /bin/bash<<EOF
ln -s /etc/portage/make.conf /etc/make.conf
source /etc/profile
eselect profile set 22
emerge --sync
emerge -1 dev-util/pkgconf
emerge --rage-clean dev-libs/glib x11-misc/shared-mime-info
emerge -vuND --with-bdeps=y -1 @world
echo "sys-kernel/gentoo-sources symlink" >> /etc/portage/package.use/kernel
emerge sys-apps/haveged net-misc/ntp net-misc/dhcpcd app-admin/sudo app-portage/eix app-text/tree sys-process/lsof sys-process/htop app-editors/vim dev-vcs/git sys-boot/grub app-admin/monit app-admin/rsyslog sys-kernel/gentoo-sources sys-process/vixie-cron
EOF
