if [ "`whoami`" != "root" ]; then
	echo "this script must run as root (hint: use sudo)."
	exit 1
fi

rm -rf pkgroot
if [ ! -f VERSION ]; then echo "VERSION file missing."; exit 1; fi

PACKAGE=ims-couchdb
VERSION=`cat VERSION`-`date +%s`

cat files_to_package.txt | perl -ni make_pkg_dir.pl
# change config
for i in "default" "local"
do
	perl -pi -e 's/127.0.0.1/0.0.0.0/g' pkgroot/usr/local/etc/couchdb/$i.ini
done 
#
# by default, turn off admin party mode
perl -pi -e 's/\;admin = mysecretpassword/imsadmin = imsadmin/g' pkgroot/usr/local/etc/couchdb/local.ini

cp -dpR run pkgroot/etc/service/ims-couchdb
cp -dpR logrun pkgroot/etc/service/ims-couchdb/log/run
chmod +x pkgroot/etc/service/ims-couchdb/run
chmod +x pkgroot/etc/service/ims-couchdb/log/run
chown couchdb:couchdb pkgroot/etc/service/ims-couchdb/run
chown couchdb:couchdb pkgroot/etc/service/ims-couchdb/log/run

mkdir -p pkgroot/etc/service/ims-couchdb/log/main
chown couchdb:couchdb pkgroot/etc/service/ims-couchdb/log/main

for i in var/log/couchdb var/lib/couchdb var/run/couchdb etc/couchdb 
do
	mkdir -p pkgroot/usr/local/$i
done

mkdir pkgroot/DEBIAN
chown -R couchdb:couchdb  pkgroot/usr/local

tee pkgroot/DEBIAN/control <<EOM
Package: $PACKAGE
Version: $VERSION
Architecture: amd64
Maintainer: "Suraj Kumar" <suraj.kumar@inmobi.com>
Depends: libicu48, erlang, libmozjs185-1.0, daemontools, daemontools-run
Description: CouchDB 1.4.0 packaged for IMS
 Build date: `date`
EOM

dpkg-deb --build pkgroot ${PACKAGE}_${VERSION}.deb
