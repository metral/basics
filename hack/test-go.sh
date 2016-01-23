#!/bin/bash

# Graciously copied/modeled after Kubernetes
# https://github.com/kubernetes/kubernetes/blob/master/hack

# statically build a binary for each golang pkg (from a gb project)
# if no golang pkg's are provided, we discover *_test.go files in the
# GB_PROJ_ROOT dir provided as defined in find_dirs
set -o errexit
set -o nounset
set -o pipefail

EXPECTEDARGS=1
if [ $# -lt $EXPECTEDARGS ]; then
    echo "Usage: $0 <GB_PROJ_ROOT> <OPTIONAL_GO_PKGS>"
    echo "i.e. $0 ."
    echo "i.e. $0 /home/metral/foobar github.com/metral/foobar"
    exit 0
fi

GB_PROJ_ROOT=`readlink -f $1`
GB_PROJ_SRC=$GB_PROJ_ROOT/src

GOPATH=${GB_PROJ_ROOT}:${GB_PROJ_ROOT}/vendor

GO_PKGS="${@:2}"

# find all *_test.go files in GB_PROJ_SRC that are NOT in the -path / -o path's
# specified
test::find_dirs() {
(
    cd ${GB_PROJ_SRC}
    find . -not \( \
        \( \
        -path '*/tests/integration/*' \
        \) -prune \
        \) -name '*_test.go' -print0 | xargs -r -0n1 dirname | sed 's|^\./||' | sort -u
    )
}

setup_env(){
    export GOPATH
}

golang::test_pkgs() {
    setup_env

    local -a testcases=()

    # create test cases based on optional pkg's passed in
    for arg in $GO_PKGS; do
        testcases+=("${arg}")
    done

    # if no package was passed in, then testcases is empty.
    # thus, search for all relevant tests listed in
    # find_dirs and set testcases to them
    if [[ ${#testcases[@]} -eq 0 ]]; then
        testcases=($(test::find_dirs))
    fi
    set -- "${testcases[@]+${testcases[@]}}"

    # iterate through all of the golang pkg tests in testcases
    for pkg in "${testcases[@]:+${testcases[@]}}"; do
        go test -v ${pkg}
    done
}

golang::test_pkgs
