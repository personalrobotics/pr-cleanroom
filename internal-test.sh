#!/bin/bash
CATKIN_BUILD='catkin build --no-status -p 1 -i'
BUILD_PATH='build'
OUTPUT_PATH='test_results'
LIBEATMYDATA_PATH=$(find /usr/lib/ -name libeatmydata.so)

export SHELL="${SHELL=/bin/bash}"
export LD_PRELOAD="${LIBEATMYDATA_PATH}:${LD_PRELOAD}"

. devel/setup.bash

set -x

if [ "$#" -eq 0 ]; then
    set -x
    ${CATKIN_BUILD} --catkin-make-args tests
    ${CATKIN_BUILD} --catkin-make-args run_tests
    set +x
else
    set -x
    ${CATKIN_BUILD} --no-deps --catkin-make-args tests -- "$@"
    ${CATKIN_BUILD} --no-deps --catkin-make-args run_tests -- "$@"
    set +x
fi


mkdir -p "${OUTPUT_PATH}"

for package_name in $(ls "${BUILD_PATH}"); do
    if [ -d "${BUILD_PATH}/${package_name}/test_results/${package_name}" ]; then
        echo "Copying test results for package '${package_name}'."
        cp -r "${BUILD_PATH}/${package_name}/test_results/${package_name}" "${OUTPUT_PATH}/${package_name}"
    fi
done

catkin_test_results "${OUTPUT_PATH}"
