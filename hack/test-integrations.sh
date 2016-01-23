#!/bin/bash

# Graciously copied/modeled after Kubernetes
# https://github.com/kubernetes/kubernetes/blob/master/hack

# statically build a binary for each golang pkg (from a gb project)
set -o errexit
set -o nounset
set -o pipefail

SCRIPTS_ROOT=$(dirname "${BASH_SOURCE}")

GB_PROJ_ROOT=`readlink -f $1`
GB_PROJ_SRC=$GB_PROJ_ROOT/src

# find all *_test.go files in GB_PROJ_SRC that ARE in the -path / -o path's
# specified
test::find_dirs() {
(
    cd ${GB_PROJ_SRC}
    find . \( \
        \( \
        -path '*/tests/integration/*' \
        \) -prune \
        \) -name '*_test.go' -print0 | xargs -r -0n1 dirname | sed 's|^\./||' | sort -u
    )
}


testcases=()
testcases=($(test::find_dirs))

# iterate through all of the golang integration tests in testcases
for pkg in "${testcases[@]:+${testcases[@]}}"; do
TEST_INTEGRATION="true" \
    $SCRIPTS_ROOT/test-go.sh $GB_PROJ_ROOT ${pkg}
done
