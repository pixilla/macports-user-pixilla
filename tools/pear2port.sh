#!/bin/bash

[ ${MAINTAINERS+1} ] || MAINTAINERS="nomaintainer"
[ ${EXTRACT_SUFFIX+1} ] || EXTRACT_SUFFIX=".tgz"
package=${1}
if [ "x${package}" == "x" ]
then
    echo "Error: No package name given!"
    echo "Try something like:"
    echo "  \$ VERBOSE=yes MAINTAINERS=\"$(users) openmaintainer\" ${0} Auth"
    echo "Or, for a version other than the most recent version"
    echo "  \$ VERBOSE=yes MAINTAINERS=\"$(users) openmaintainer\" ${0} Auth 0.3.1"
    exit 
fi
[ "x${VERBOSE}" == "xyes" ] && echo "Package: ${package}"

if [ "x${2}" == "x" ]
then
version=\
$(curl -s http://pear.php.net/package/${package}/download | \
grep -o -P "http://download.pear.php.net/package/${package}-((?!${EXTRACT_SUFFIX}).*)${EXTRACT_SUFFIX}" | \
sed -e "s/.*\///g" -e "s/${package}-//g" -e "s/${EXTRACT_SUFFIX}//g")
else
version=${2}
fi
[ "x${VERBOSE}" == "xyes" ] && echo "Version: ${version}"

if [ "x${version}" == "x" ]
then
    echo "Error: Could not determine version!"
    echo "Version: ${version}"
    exit 
fi
distname=${package}-${version}

mkdir pear-${package}
cd pear-${package}
[ "x${VERBOSE}" == "xyes" ] && echo "building Portfile..."
cat << EOF > Portfile
# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# \$Id\$

PortSystem          1.0
PortGroup           php5pear 1.0

php5pear.setup      ${package} ${version}
categories-append   net www
platforms           darwin
maintainers         ${MAINTAINERS}

description         PEAR ${package} package
long_description    \${description}

EOF

sleep 1
[ "x${VERBOSE}" == "xyes" ] && echo "port -o fetch..."
sudo port -o fetch > /dev/null 2>&1
distfile=$(port -o distfiles | grep "\[${distname}${EXTRACT_SUFFIX}\]" | awk '{print $2}')
distfile_sha1=$(openssl sha1 ${distfile} | awk '{print $2}')
distfile_rmd160=$(openssl rmd160 ${distfile} | awk '{print $2}')
cat << EOF >> Portfile
checksums           sha1    ${distfile_sha1} \\
                    rmd160  ${distfile_rmd160}
EOF

[ "x${VERBOSE}" == "xyes" ] && echo "removing sources..."

[ "x${VERBOSE}" == "xyes" ] && echo "port -o extract..."
sudo port -o extract > /dev/null 2>&1
deps=''
count=0
IFS=$'\n'
[ "x${VERBOSE}" == "xyes" ] && echo "port -o build to check for deps..."
sleep 1
for dep in $(sudo port -o -v build | grep -P "${package} requires package")
do
    depname=$(echo $dep | awk '{print $5}' | sed -e "s/pecl\//php5\//g" -e "s/\"//g" -e "s/\//-/g")
    count=$((count+1))
    if [[ $count -eq 1 ]]
    then
        echo "" >> Portfile
        echo -n "depends_lib-append  port:${depname}" >> Portfile
    else
        echo " \\" >> Portfile
        echo -n "                    port:${depname}" >> Portfile
    fi
done
if [[ $count -gt 0 ]]
then
    echo "" >> Portfile
fi
unset IFS
[ "x${VERBOSE}" == "xyes" ] && echo "port -o clean..."
sudo port -o clean > /dev/null 2>&1
[ "x${VERBOSE}" == "xyes" ] &&echo "final Portfile..."
cat Portfile
cd ..
