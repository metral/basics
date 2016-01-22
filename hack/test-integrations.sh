#!/bin/bash

# Graciously copied/modeled after Kubernetes
# https://github.com/kubernetes/kubernetes/blob/master/hack

# statically build a binary for each golang pkg (from a gb project)
set -o errexit
set -o nounset
set -o pipefail

# TODO set CONF_FILE
# TODO set GO_PKG

TEST_INTEGRATION="true" \
    ./test-go.sh \
    $GO_PKG/tests/integration
