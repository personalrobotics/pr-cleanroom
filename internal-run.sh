#!/bin/bash -e
CATKIN_BUILD='catkin build --no-status'
BUILD_PATH='build'
OUTPUT_PATH='test_results'

export SHELL="${SHELL=/bin/bash}"
export LD_PRELOAD="/usr/lib/libeatmydata/libeatmydata.so:${LD_PRELOAD}"

. devel/setup.bash
"$@"
