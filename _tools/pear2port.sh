#!/bin/bash

extract_suffix='.tgz'
package=${1}
if [ "${package}x" == "x" ]
then
    echo "Error: No package name given!"
    echo "Try: \$ ${0} Auth"
    echo "Or, for something other then the most recent version"
    echo "Try: \$ ${0} Auth 0.3.1"
    exit 
fi
echo "Package: ${package}"

if [ "${2}x" == "x" ]
then
version=\
$(curl -s http://pear.php.net/package/${package}/download | \
grep -o -P "http://download.pear.php.net/package/${package}-((?!\.tgz).*)\.tgz" | \
sed -e "s/.*\///g" -e "s/${package}-//g" -e "s/\.tgz//g")
else
version=${2}
fi
echo "Version: ${version}"

if [ "${version}x" == "x" ]
then
    echo "Error: Could not determine version!"
    echo "Version: ${version}"
    exit 
fi
distname=${package}-${version}

curl -s http://download.pear.php.net/package/${distname}${extract_suffix} -O
mkdir pear-${package}
cat << EOF > pear-${package}/Portfile
# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# \$Id\$

PortSystem          1.0
PortGroup           php5pear 1.0

php5pear.setup      ${package} ${version}
categories-append   net www
platforms           darwin
maintainers         pixilla

description         PEAR ${package} package
long_description    \${description}

checksums           sha1    $(openssl sha1 ${distname}${extract_suffix} | awk '{print $2}') \\
                    rmd160  $(openssl rmd160 ${distname}${extract_suffix} | awk '{print $2}')
EOF
cd pear-${package}
cat Portfile
port lint --nitpick
sudo port -v build
sudo port clean
cd ..
rm ${distname}${extract_suffix}
