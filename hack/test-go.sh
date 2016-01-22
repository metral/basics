#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# run golang tests
PROJ_ROOT="$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ))"
GO_PKGS=github.com/metral/core
PROJ_ROOT=$PROJ_ROOT/src/$GO_PKGS

export GOPATH=$(pwd):$(pwd)/vendor
export CONF_FILEPATH=$(pwd)/vendor/src/github.com/metral/nucleus/pkg/config/test_config.toml

test::find_dirs() {
(
    cd ${PROJ_ROOT}
    find . -not \( \
        \( \
        -path './tests/integration/*' \
        \) -prune \
        \) -name '*_test.go' -print0 | xargs -r -0n1 dirname | sed 's|^\./||' | sort -u
    )
}

# Filter out arguments that start with "-" and move them to goflags.
testcases=()
for arg; do
    if [[ "${arg}" == -* ]]; then
        goflags+=("${arg}")
    else
        testcases+=("${arg}")
    fi
done
if [[ ${#testcases[@]} -eq 0 ]]; then
    testcases=($(test::find_dirs))
fi
set -- "${testcases[@]+${testcases[@]}}"

TEST_PKGS="${@+${@/#/${GO_PKGS}/}}"
if [ ! -z $TEST_PKGS ]; then
    go test \
        -v \
        -p 1 \
        $TEST_PKGS
fi
