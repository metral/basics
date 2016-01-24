#!/bin/bash

# perform a manual update of a vendored lib, which is a gb project, from the gb
# project that is running this script is running on behalf of
# (as gb doesn't do vendoring of other gb projects, yet)

EXPECTEDARGS=2
if [ $# -lt $EXPECTEDARGS ]; then
  echo "Usage: $0 <GB_LIB_GITHUB> <GB_LIB_BRANCH>"
  echo "i.e. github.com/foo/bar master"
exit 0
fi

# get path of gb lib & the lib's name
GB_LIB_GITHUB=ssh://git@$1
GB_LIB_BRANCH=$2
GB_LIB_NAME=`basename $GB_LIB_GITHUB`

# make a copy of the lib to temp to use in manual vendoring (so we don't
# accidentally screw something up in the real lib)
TEMP_GB_LIB_GITHUB="/tmp/$GB_LIB_NAME-`date +%s`"
git clone --branch $GB_LIB_BRANCH $GB_LIB_GITHUB $TEMP_GB_LIB_GITHUB
cp vendor/manifest $TEMP_GB_LIB_GITHUB
cat $TEMP_GB_LIB_GITHUB/manifest

rm -rf vendor
mkdir -p vendor/src
# copy lib src & vendored deps to this projects vendor
cp -r $TEMP_GB_LIB_GITHUB/vendor/src/* vendor/src/
cp -r $TEMP_GB_LIB_GITHUB/src/* vendor/src/

# get hash of lib being vendored to know what version we're depending on
pushd $TEMP_GB_LIB_GITHUB > /dev/null
GB_LIB_HASH=`git rev-parse --short HEAD`
popd > /dev/null
echo "\"$GB_LIB_NAME\" : $GB_LIB_HASH" | tee manual_manifest

# restore old deps (if there were any)
mv $TEMP_GB_LIB_GITHUB/manifest vendor/
gb vendor restore

# cleanup
rm -rf $TEMP_GB_LIB_GITHUB
