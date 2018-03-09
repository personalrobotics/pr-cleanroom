#!/bin/bash -e
CATKIN_BUILD='catkin build --no-status'
BUILD_PATH='build'
OUTPUT_PATH='test_results'
LIBEATMYDATA_PATH=$(find /usr/lib/ -name libeatmydata.so)

export SHELL="${SHELL=/bin/bash}"
export LD_PRELOAD="${LIBEATMYDATA_PATH}:${LD_PRELOAD}"

. devel/setup.bash
"$@"
