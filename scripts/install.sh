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

cat > /mnt/gentoo/etc/portage/make.conf << EOF
CHOST="x86_64-pc-linux-gnu"

CFLAGS="-march=native -O2 -pipe"
CXXFLAGS="\${CFLAGS}"
ACCEPT_KEYWORDS="~*"

MAKEOPTS="-j${NPROCS}"

LINGUAS="en en_US"
L10N="en en_US"
PYTHON_TARGETS="python2_7 python3_6"
PYTHON_SINGLE_TARGET="python3_6"
POSTGRES_TARGETS="postgres10"
GRUB_PLATFORMS="efi-64 pc qemu"
CPU_FLAGS_X86="avx avx2 aes mmx sse sse2 ssse3 sse4_1 sse4_2"

SYSTEM="threads jemalloc udev vim-syntax"
SYSTEM="\${SYSTEM} jit pcre pcre-jit -bindist"
SYSTEM="\${SYSTEM} uuid gmp audit"
AUTH=""
NET="curl json openssl"
NET="\${NET} -sslv3 -sslv2"

LANGS="perl -python"
DB="lmdb"
VCS="git"

USE="\${USE} \${SYSTEM} \${AUTH} \${LANGS} \${DB} \${VCS} \${NET}"

PORTDIR="/usr/portage"
DISTDIR="\${PORTDIR}/distfiles"
PKGDIR="\${PORTDIR}/packages"
EOF

cat > /mnt/gentoo/etc/locale.gen << EOF
en_US ISO-8859-1
en_US.UTF-8 UTF-8
EOF

mkdir -p /mnt/gentoo/etc/portage/package.use
cat > /mnt/gentoo/etc/portage/package.use/system << EOF
sys-kernel/gentoo-sources symlink
add-admin/rsyslog -gnutls relp normalize
dev-libs/librelp -gnutls

net-misc/ntp parse-clocks

dev-lang/perl ithreads
EOF

mv /tmp/config.gz /mnt/gentoo
echo "/dev/sda2   /            ext4    noatime,discard      0 1" >  /mnt/gentoo/etc/fstab

echo "= BUILDING UTILITIES ===================================================="
chroot /mnt/gentoo /bin/bash<<EOF
ln -s /etc/portage/make.conf /etc/make.conf
source /etc/profile
eselect profile set 22

emerge -1 dev-util/pkgconf

emerge -vuND --with-bdeps=y --job=4 -1 @world
emerge @preserved-rebuild
echo "sys-kernel/gentoo-sources symlink" >> /etc/portage/package.use/kernel
emerge --jobs=4 sys-apps/haveged net-misc/ntp net-misc/dhcpcd app-admin/sudo app-portage/eix app-text/tree sys-process/lsof sys-process/htop app-editors/vim dev-vcs/git sys-boot/grub app-admin/monit app-admin/rsyslog sys-kernel/gentoo-sources sys-process/vixie-cron logrotate
cp /config.gz /usr/src/linux
cd /usr/src/linux
gzip -d config
mv config .config
make -j${NPROCS}
make modules_install
make headers_install
make install
echo "set timeout=0" >> /etc/grub.d/40_custom
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
useradd -m -G users,wheel gentoo
chmod o+w /etc/sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
chmod o-w /etc/sudoers
echo "gentoo:Gentoo12345!" | chpasswd
cd /etc/init.d
ln -s net.lo net.eth0
echo "modules=dhcpcd"   >> /etc/conf.d/net
echo "config_eth0=dhcp" >> /etc/conf.d/net
touch /etc/udev/rules.d/80-net-name-slot.rules
/sbin/rc-update add net.eth0   default
/sbin/rc-update add sshd       default
/sbin/rc-update add ntpd       default
/sbin/rc-update add haveged    default
/sbin/rc-update add vixie-cron default
/sbin/rc-update add rsyslog    default
/sbin/rc-update add auditd     default
EOF
