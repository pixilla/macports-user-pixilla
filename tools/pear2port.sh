#!/bin/bash

[ ${MAINTAINERS+1} ] || MAINTAINERS="nomaintainer"
[ ${EXTRACT_SUFFIX+1} ] || EXTRACT_SUFFIX=".tgz"
package=${1}
if [ "x${package}" == "x" ]
then
    echo "Error: No package name given!"
    echo "Try something like:"
    echo "  \$ VERBOSE=yes MAINTAINERS=\"$(users) openmaintainer\" ${0} Auth"
    echo "To specify a channel (default pear.php.net)"
    echo "  \$ VERBOSE=yes MAINTAINERS=\"$(users) openmaintainer\" ${0} Auth pear.php.net"
    echo "To specify a channel (required) and a version (defaults to current version)"
    echo "  \$ VERBOSE=yes MAINTAINERS=\"$(users) openmaintainer\" ${0} Auth pear.php.net 0.3.1"
    exit 
fi
[ "x${VERBOSE}" == "xyes" ] && echo "Package: ${package}"

if [ "x${2}" == "x" ]
then
channel=pear.php.net
else
channel=${2}
fi
[ "x${VERBOSE}" == "xyes" ] && echo "Channel: ${channel}"

if [ "x${3}" == "x" ]
then
/opt/local/lib/php/pear/bin/pear \
    -C /Users/brad/misc/sandbox/pear/makepearports/pear.conf \
    -c /Users/brad/misc/sandbox/pear/makepearports/pear.conf \
    config-set default_channel ${channel}
version=\
$(/opt/local/lib/php/pear/bin/pear \
    -C /Users/brad/misc/sandbox/pear/makepearports/pear.conf \
    -c /Users/brad/misc/sandbox/pear/makepearports/pear.conf \
    remote-info ${package} | \
grep "Latest" | \
awk '{print $2}')
else
version=${3}
fi
[ "x${VERBOSE}" == "xyes" ] && echo "Version: ${version}"

if [ "x${version}" == "x" ]
then
    echo "Error: Could not determine version for ${package}!"
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

php5pear.setup      ${package} ${version} ${channel}
categories-append   net www
platforms           darwin
maintainers         ${MAINTAINERS}

description         PEAR ${package} package
long_description    \${description}

EOF

sleep 1
[ "x${VERBOSE}" == "xyes" ] && echo "port -o fetch..."
[ "x${VERBOSE}" == "xyes" ] && sudo port -o fetch || sudo port -o fetch > /dev/null 2>&1
distfile=$(port -o distfiles | grep "\[${distname}${EXTRACT_SUFFIX}\]" | awk '{print $2}')
distfile_rmd160=$(openssl rmd160 ${distfile} | awk '{print $2}')
distfile_sha256=$(openssl sha256 ${distfile} | awk '{print $2}')
cat << EOF >> Portfile
checksums           rmd160  ${distfile_rmd160} \\
                    sha256  ${distfile_sha256}
EOF

[ "x${VERBOSE}" == "xyes" ] && echo "removing sources..."

[ "x${VERBOSE}" == "xyes" ] && echo "port -o extract..."
[ "x${VERBOSE}" == "xyes" ] && sudo port -o extract || sudo port -o extract > /dev/null 2>&1
deps=''
count=0
IFS=$'\n'
[ "x${VERBOSE}" == "xyes" ] && echo "port -o build to check for deps..."
sleep 1
for dep in $(sudo port -o -v build | grep -P "${package} requires package" | grep -v -E '"pear/PEAR"|"pear/Archive_Tar"|"pear/Structures_Graph"|"pear/Console_Getopt"|"pear/XML_Util"')
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
[ "x${VERBOSE}" == "xyes" ] && sudo port -o clean || sudo port -o clean > /dev/null 2>&1
[ "x${VERBOSE}" == "xyes" ] && echo "final Portfile..."
cat Portfile
cd ..
