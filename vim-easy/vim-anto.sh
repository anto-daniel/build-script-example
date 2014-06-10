#!/bin/bash 

PACKAGE=vim-anto
VERSION="0.0.1"

mkdir -p pkgroot/tmp
cp -dpR .vimrc pkgroot/tmp
cp -dpR .vim/  pkgroot/tmp

mkdir pkgroot/DEBIAN

tee pkgroot/DEBIAN/control <<EOM
Package: $PACKAGE
Version: $VERSION
Architecture: all 
Maintainer: "Anto Daniel" <anto.daniel@inmobi.com>
Depends: vim
Description: vim for programmers 
EOM

tee pkgroot/DEBIAN/postinst <<EOM
#!/bin/bash 
cd
DIR=\$(pwd)
cp -rf /tmp/.vimrc \$DIR
cp -rf /tmp/.vim \$DIR

EOM
chmod +x pkgroot/DEBIAN/postinst
dpkg-deb --build pkgroot ${PACKAGE}_${VERSION}.deb
rm -r pkgroot
