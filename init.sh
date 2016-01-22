#!/bin/bash

# create dir for manual gb vendoring of a library
mkdir -p vendor/src

# create dir for build-go static bins
mkdir -p _output

# create dirs for local wercker build & deploy logs
mkdir -p _output/builds
mkdir -p _output/deploys
