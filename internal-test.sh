#!/bin/bash
CATKIN_BUILD='catkin build --no-status'
BUILD_PATH='build'
OUTPUT_PATH='test_results'

export SHELL="${SHELL=/bin/bash}"
export LD_PRELOAD="/usr/lib/libeatmydata/libeatmydata.so:${LD_PRELOAD}"

. devel/setup.bash

if [ "$#" -eq 0 ]; then
    ${CATKIN_BUILD} --catkin-make-args tests
    ${CATKIN_BUILD} --catkin-make-args run_tests
else
    # Split the arguments into Catkin and non-Catkin packages.
    declare -a PACKAGES_CATKIN
    declare -a PACKAGES_CMAKE

    for package_name in "$@"; do
        if $(rospack find "${package_name}"); then
            PACKAGES_CATKIN+="${package_name}"
        else
            PACKAGES_CMAKE+="${package_name}"
        fi
    done

    ${CATKIN_BUILD} --no-deps -p1 --make-args tests -- "$@"

    if [ "${#PACKAGES_CATKIN[@]}" -ne 0 ]; then
        ${CATKIN_BUILD} --no-deps -p1 --catkin-make-args run_tests -- "${PACKAGES_CATKIN}"
    fi

    if [ "${#PACKAGES_CMAKE[@]}" -ne 0 ]; then
        set -e
        ${CATKIN_BUILD} --no-deps -p1 --make-args test -- "${PACKAGES_CMAKE}"
        set +e
    fi
fi

mkdir -p "${OUTPUT_PATH}"

for package_name in $(ls "${BUILD_PATH}"); do
    if [ -d "${BUILD_PATH}/${package_name}/test_results/${package_name}" ]; then
        echo "Copying test results for package '${package_name}'."
        cp -r "${BUILD_PATH}/${package_name}/test_results/${package_name}" "${OUTPUT_PATH}/${package_name}"
    fi
done

catkin_test_results "${OUTPUT_PATH}"
