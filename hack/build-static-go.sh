#!/bin/bash

# Graciously copied/modeled after Kubernetes
# https://github.com/kubernetes/kubernetes/blob/master/hack

# statically build a binary for each golang pkg (from a gb project)
set -o errexit
set -o nounset
set -o pipefail

EXPECTEDARGS=2
if [ $# -lt $EXPECTEDARGS ]; then
  echo "Usage: $0 <GB_PROJ_ROOT> <GO_PACKAGE(S)>"
  echo "i.e. /home/metral/foobar github.com/metral/foobar"
  echo "i.e. /home/metral/foobar github.com/metral/foobar github.com/metral/foobar/cmd/foo"
exit 0
fi

PROJ_ROOT=`readlink -f $1`

GOPATH=${PROJ_ROOT}:${PROJ_ROOT}/vendor

COMPILE_SUBPATH="bin"
COMPILE_BINPATH="${PROJ_ROOT}/${COMPILE_SUBPATH}"

OUTPUT_SUBPATH="_output"
OUTPUT="${PROJ_ROOT}/${OUTPUT_SUBPATH}"
OUTPUT_BINPATH="${OUTPUT}/bin"

GO_PKGS="${@:2}"

# bin dir holding all static bins compiled
mkdir -p $COMPILE_BINPATH
# bin dir that holds a copy of the static bins compiled
mkdir -p $OUTPUT_BINPATH

# setup GOPATH to build a gb project using `go build` since gb can't static
# build yet
golang::setup_env(){
    export GOPATH
}

# get targets from args and statically build their bins
golang::build_binaries() {
    golang::setup_env

    local -a targets=()
    if [[ ${#targets[@]} -eq 0 ]]; then
        targets=("${GO_PKGS[@]}")
    fi

    local -a statics=()
    local -a nonstatics=()
    local -a tests=()
    for target in "${targets[@]}"; do
        statics+=($target)
    done

    for binary in "${statics[@]:+${statics[@]}}"; do
        local outfile=$PROJ_ROOT/bin/$(basename "${binary}")
        CGO_ENABLED=0  GOOS=linux go build -o "${outfile}" \
        -a -installsuffix cgo -ldflags '-w -extld ld -extldflags -static' \
        -a -x "${binary}"
    done
}

# copy static bins from COMPILE_BINPATH to $OUTPUT_BINPATH
golang::place_bins(){
  cp -r $COMPILE_BINPATH/* $OUTPUT_BINPATH
}

golang::build_binaries
golang::place_bins
