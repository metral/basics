#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

ROOT=$(dirname "${BASH_SOURCE}")/..
TEST_INTEGRATION="true" \
    $ROOT/hack/test-go.sh tests/integration
