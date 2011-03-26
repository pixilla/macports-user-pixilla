# $Id: php5pear-1.0.tcl 76571 2011-02-28 15:42:47Z pixilla@macports.org $
# 
# Copyright (c) 2009 The MacPorts Project
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of The MacPorts Project nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# 
# This PortGroup automatically sets up the standard environment for installing
# a PHP PEAR classes.
# 
# Usage:
# 
#   PortGroup           php5pear 1.0
#   php5pear.setup      package version channel
# 
# where package is the name of the PEAR package (e.g. AUTH), version is its
# version, and channel is the channel hosting the package (default: pear.php.net).
# 

default package {}
default version {}
default channel pear.php.net

proc php5pear.setup {package version {channel "pear.php.net"}} {
    global worksrcpath distname extract.suffix master_sites
    global packagingroot

    set package         [lindex ${package} 0]
    name                pear-${package}
    version             ${version}
    categories          php
    distname            ${package}-${version}
    extract.suffix      .tgz
    homepage            http://${channel}/package/${package}
    master_sites        http://download.${channel}/package
    livecheck.type      regex
    livecheck.url       http://pear.php.net/package/${package}/download
    livecheck.regex     "http://download.${channel}/package/${package}-((?!\.tgz).*)${extract.suffix}"

    use_parallel_build  yes
    depends_lib         path:bin/phpize:php5 port:php5-pear
    extract.mkdir       yes
    set packagingroot   ${worksrcpath}/packagingroot    

    extract {
        copy ${distpath}/${distname}${extract.suffix} ${worksrcpath}
    }

    configure {
        xinstall -d ${worksrcpath}/build
    }
    
    build {
#        system "TZ=\"UTC\" ${prefix}/libexec/php/bin/pear -C ${prefix}/libexec/php/etc/pear.conf channel-update ${channel}"
        system "cd ${worksrcpath} && TZ=\"UTC\" ${prefix}/libexec/php/bin/pear -C ${prefix}/libexec/php/etc/pear.conf install --nodeps --offline --ignore-errors --packagingroot=${packagingroot} ${distname}${extract.suffix}"
    }
    
    destroot {
        xinstall -d ${destroot}${prefix}/lib/php/pear
        foreach path [glob -nocomplain -directory ${packagingroot}${prefix}/lib/php/pear *] {
            copy ${path} ${destroot}${prefix}/lib/php/pear
        }
    }
    
}
