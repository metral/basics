#!/bin/bash

# Graciously copied/modeled after Kubernetes
# https://github.com/kubernetes/kubernetes/blob/master/hack

# statically build a binary for each golang pkg (from a gb project)
# if no golang pkg's are provided, we discover *_test.go files in the
# GB_PROJ_ROOT dir provided as defined in find_dirs
#set -o errexit
set -o nounset
set -o pipefail

EXPECTEDARGS=3
if [ $# -lt $EXPECTEDARGS ]; then
    echo "Usage: $0 <GB_PROJ_ROOT> <CMD> <URL>"
    echo "i.e. $0 ."
    echo "i.e. $0 /home/metral/foobar"
    exit 1
fi

GB_PROJ_ROOT=`readlink -f $1`
CMD=$2
URL=$3

OUTPUT_SUBPATH="_output"
OUTPUT="${GB_PROJ_ROOT}/${OUTPUT_SUBPATH}"
OUTPUT_BINPATH="${OUTPUT}/bin"

# Print a status line.  Formatted to show up in a stream of output.
log::status() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "+++ $timestamp $1"
  shift
  for message; do
    echo "    $message"
  done
}

# Log an error but keep going.  Don't dump the stack or exit.
log::error() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "!!! $timestamp ${1-}" >&2
  shift
  for message; do
    echo "    $message" >&2
  done
}

# Print an usage message to stderr.  The arguments are printed directly.
log::usage() {
  echo >&2
  local message
  for message; do
    echo "$message" >&2
  done
  echo >&2
}

# wait for url to respond
util::wait_for_url() {
  local url=$1
  local wait=${2:-0.5}
  local times=${3:-5}

  which curl >/dev/null || {
    log::usage "curl must be installed"
    exit 1
  }

  local i
  for i in $(seq 1 $times); do
    local out
    if out=$(curl -fs $url 2>/dev/null); then
      log::status "On try ${i}: ${out}"
      return 0
    fi
    sleep ${wait}
  done
  log::error "Timed out waiting for answer at ${url}; tried ${times} waiting ${wait} between each"
  return 1
}

log::status "Starting..."
eval "$CMD 1>&2 &"
APISERVER_PID=$!

function cleanup()
{
    [[ -n "${APISERVER_PID-}" ]] && kill "${APISERVER_PID}" 1>&2 2>/dev/null
    log::status "Clean up complete"
}

run_tests(){
    util::wait_for_url $URL 1 5
    local status=$?
    cleanup
    return ${status}
}

run_tests
