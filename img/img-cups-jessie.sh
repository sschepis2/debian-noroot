#!/bin/sh

set -x

APT_CACHER=
[ -e /etc/init.d/apt-cacher* ] && APT_CACHER=/localhost:3142

DIST=jessie

for ARCH in i386/x86 armhf/armeabi-v7a; do
ARCH_ANDROID=`echo $ARCH | sed 's@.*/@@'`
ARCH_DEBIAN=`echo $ARCH | sed 's@/.*@@'`
DIR=dist-cups-$DIST/img-$ARCH_ANDROID
sudo rm -r -f $DIR
mkdir -p $DIR
STRIP_LIST=`cat strip.list`
STRIP_LIST=`echo $STRIP_LIST | sed 's/ /,/g'`
# --exclude=$STRIP_LIST \
sudo qemu-debootstrap --arch=$ARCH_DEBIAN --verbose \
		--components=main,contrib,non-free \
		--include=cups,cups-client,smbclient,printer-driver-all-enforce,cups-filters,foomatic-db-compressed-ppds \
		--exclude=ghostscript-cups,foomatic-filters \
		$DIST $DIR http:/$APT_CACHER/ftp.ua.debian.org/debian/ 2>&1 | tee debootstrap-$ARCH_ANDROID.log \
&& cat sources-jessie.list | sed "s/jessie/$DIST/g" | sudo tee $DIR/etc/apt/sources.list > /dev/null \
&& sudo ./prepare-img-proot.sh --strip "usr/share/X11 usr/share/zoneinfo usr/share/calendar" "ghostscript-cups foomatic-filters" --noarchive $DIR $ARCH_ANDROID \
| tee -a debootstrap-$ARCH_ANDROID.log
done
cd dist-cups-$DIST
rm -f img-armeabi-v7a/busybox img-x86/busybox
../merge-dirs.sh img-armeabi-v7a img-x86 img
tar c * | xz -8 > ../dist-cups-$DIST.tar.xz
