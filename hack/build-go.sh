#!/bin/bash

# Graciously copied/modeled after Kubernetes
# https://github.com/kubernetes/kubernetes/blob/master/hack

# statically build a binary of a golang pkg from a gb project
set -o errexit
set -o nounset
set -o pipefail

EXPECTEDARGS=2
if [ $# -lt $EXPECTEDARGS ]; then
  echo "Usage: $0 <GB_PROJ_ROOT> <GO_PACKAGE>"
  echo "i.e. /home/metral/foobar github.com/metral/foobar"
  echo "i.e. /home/metral/foobar github.com/metral/foobar/cmd/foo"
exit 0
fi

PROJ_ROOT=$1
#PROJ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#PROJ_ROOT=$( dirname $PROJ_ROOT)

GO_PACKAGE=$2
GOPATH=${PROJ_ROOT}:${PROJ_ROOT}/vendor

OUTPUT_SUBPATH="_output"
OUTPUT="${PROJ_ROOT}/${OUTPUT_SUBPATH}"
OUTPUT_BINPATH="${OUTPUT}/bin"

#readonly SERVER_TARGETS=${GO_PACKAGE-""}
readonly ALL_TARGETS=(
  #"${SERVER_TARGETS[@]}"
  $GO_PACKAGE
)

golang::binaries_from_targets() {
  local target
  for target; do
    if [[ "${target}" =~ ^([[:alnum:]]+".")+[[:alnum:]]+"/" ]]; then
      echo "${target}"
    else
      if [ -z "${target}" ]; then
        echo "${GO_PACKAGE}"
      else
        echo "${GO_PACKAGE}/${target}"
      fi
    fi
  done
}

golang::setup_env(){
    export GOPATH
}

golang::build_binaries() {
    golang::setup_env

    local -a targets=()
    if [[ ${#targets[@]} -eq 0 ]]; then
        targets=("${ALL_TARGETS[@]}")
    fi

    local binaries
    binaries=($(golang::binaries_from_targets "${targets[@]}"))

    local -a statics=()
    local -a nonstatics=()
    local -a tests=()
    for binary in "${binaries[@]}"; do
        statics+=($binary)
    done

    for binary in "${statics[@]:+${statics[@]}}"; do
        local outfile=$PROJ_ROOT/bin/$(basename "${binary}")
        CGO_ENABLED=0  GOOS=linux go build -o "${outfile}" \
        -a -installsuffix cgo -ldflags '-w -extld ld -extldflags -static' \
        -a -x "${binary}"
    done
}

golang::place_bins(){
  mkdir -p $OUTPUT_BINPATH
  cp -r $PROJ_ROOT/bin/* $OUTPUT_BINPATH
}

golang::build_binaries
golang::place_bins
