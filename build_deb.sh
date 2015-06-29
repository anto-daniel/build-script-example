#!/bin/bash
#set -x

sudo rm -rf build/
# Declaring Variables
PROJECT="$1"
ENV="$2"
BUILDROOT=build
BUILDDIR=$BUILDROOT/usr/local/share/ims-couchapps/$PROJECT
POSTINSTDIR=/usr/local/share/ims-couchapps/$PROJECT
if [ ! -f $PROJECT/VERSION ]; then echo Need VERSION file; exit 1;fi

VERSION=`cat $PROJECT/VERSION`-`date +%s`
PKGNAME=$PROJECT
KANSODIR="./node_modules/kanso"

mkdir -p $BUILDROOT/DEBIAN
mkdir -p $BUILDDIR
  
npm_and_kanso_install() {
 	
    OLDDIR=`pwd`
	cd $PROJECT
	npm install
	$KANSODIR/bin/kanso install
	cd $OLDDIR
	cp -dpR $PROJECT/node_modules $BUILDDIR/
	cp -dpR $PROJECT/packages $BUILDDIR/
} 

copy_project_files_to_build_dir() {

	for file in `cat $PROJECT/kanso.json | egrep "\"attachments\": \[|modules" | awk -F: '{print $2}' | sed 's/\[//g;s/\"/\ /g;s/\]//g;s/\,//g'`
	do
	    if [[ "$file" == null ]]; then
	 	# No files returned, no files will get copied.
		break
	    else
		# Copying files to Build directory
		cp -rf $PROJECT/$file $BUILDDIR
	    fi
	done
	#ls -l ${PROJECT} | awk '{print $9}' | egrep -v "conf|^$" | xargs -I {} cp -dpR ${PROJECT}/{} $BUILDDIR
	rsync -a --exclude conf ${PROJECT}/ $BUILDDIR
}

copy_project_files_to_build_dir
npm_and_kanso_install



build_control() {
cat > $BUILDROOT/DEBIAN/control <<EOM
Package: $PKGNAME
Version: $VERSION
Architecture: all
Depends: ims-nodejs, ${PROJECT}-conf
Description: ${PROJECT} CouchApp
Maintainer: Anto Daniel <anto.daniel@inmobi.com>

EOM
}

build_control

build_postinst() {

cat > postinst <<EOM
#! /bin/bash

CONFIGFILE=$POSTINSTDIR/conf/$ENV/config.yaml
HOST=\`cat \$CONFIGFILE | grep 'host' | cut -f2 -d: | sed 's/\ //'  \`
PORT=\`cat \$CONFIGFILE | grep 'port' | cut -f2 -d: | sed 's/\ //'  \`
cd $POSTINSTDIR
$KANSODIR/bin/kanso push http://\$HOST:\$PORT/$PROJECT

EOM

}

build_postinst

cp postinst $BUILDROOT/DEBIAN/
chmod +x $BUILDROOT/DEBIAN/postinst
sudo chown root:root $BUILDROOT

dpkg-deb --build $BUILDROOT ${PROJECT}/${PKGNAME}_${VERSION}.deb


# if optional argument
sudo rm -rf $BUILDROOT/
mkdir -p $BUILDROOT/DEBIAN/
mkdir -p $BUILDDIR/

build_conf() {

cp -dpRn $PROJECT/conf $BUILDDIR/

cat > $BUILDROOT/DEBIAN/control <<EOM

Package: $PKGNAME-conf-$ENV
Provides: $PKGNAME-conf
Version: $VERSION
Architecture: all
Depends: ${PROJECT}
Description: ${PROJECT} config for $ENV
Maintainer: Anto Daniel <anto.daniel@inmobi.com>

EOM


dpkg-deb --build $BUILDROOT ${PROJECT}/${PKGNAME}-conf-${ENV}_${VERSION}.deb

}

build_conf
