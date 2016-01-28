#!/bin/bash

# perform a manual update of a vendored lib, which is a gb project, from the gb
# project that is running this script is running on behalf of
# (as gb doesn't do vendoring of other gb projects, yet)

EXPECTEDARGS=1
if [ $# -lt $EXPECTEDARGS ]; then
  echo "Usage: $0 <GB_LIB> <GB_LIB_GIT_BRANCH>"
  echo "i.e. remote: github.com/foo/bar master"
  echo "or local: ../dev/foobar"
exit 0
fi

# get gb lib location - either github.com URL or local directory
GB_LIB=$1
GB_LIB_NAME=`basename $GB_LIB`
TEMP_GB_LIB_GITHUB="/tmp/$GB_LIB_NAME-`date +%s`"

if [[ $GB_LIB == github.com* ]]; then
    # clone a copy of the lib to use in manual vendoring - remote
    GB_LIB_BRANCH=$2
    GB_LIB_GITHUB=ssh://git@$GB_LIB
    git clone --branch $GB_LIB_BRANCH $GB_LIB_GITHUB $TEMP_GB_LIB_GITHUB
else
    # make a copy of the lib to temp to use in manual vendoring - local
    cp -r $GB_LIB $TEMP_GB_LIB_GITHUB
fi

# copy this gb app's vendor manifest
cp vendor/manifest $TEMP_GB_LIB_GITHUB > /dev/null 2>&1

# blow away gb app vendor dir & create a new one
rm -rf vendor
mkdir -p vendor/src

# copy gb lib src & vendored deps to gb app's vendor/src
cp -r $TEMP_GB_LIB_GITHUB/vendor/src/* vendor/src/
cp -r $TEMP_GB_LIB_GITHUB/src/* vendor/src/

# get hash of lib being vendored to know what version we're depending on
pushd $TEMP_GB_LIB_GITHUB > /dev/null
GB_LIB_HASH=`git rev-parse --short HEAD`
popd > /dev/null
echo "\"$GB_LIB_NAME\" : $GB_LIB_HASH" | tee manual_manifest

# restore old deps (if there were any)
mv $TEMP_GB_LIB_GITHUB/manifest vendor/ > /dev/null 2>&1
gb vendor restore

# cleanup
rm -rf $TEMP_GB_LIB_GITHUB
