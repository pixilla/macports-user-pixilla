#!/bin/sh

# Path to me.
DIRNAME=$(dirname $0)

# Get version strings.
IFS=.
read MAJOR MINOR REVISION <$DIRNAME/config/macports_version
unset IFS
MACPORTS_VERSION="${MAJOR}.${MINOR}.${REVISION}"

# Get svn revision.
SVN_REVISION=
SVNCMD=$(which svn)
if [[ "x$SVNCMD" != "x" ]]
then
    SVN_REVISION=$($SVNCMD info $DIRNAME | grep "Revision:" | awk '{print $NF}')
fi

# If revision is 99 and we have an svn revision number add it to the macports version.
if [[ $REVISION -eq 99 && "x$SVN_REVISION" != "x" ]]
then
    echo "$MACPORTS_VERSION-$SVN_REVISION" | tr -d '\n'
else
    echo "$MACPORTS_VERSION" | tr -d '\n'
fi
