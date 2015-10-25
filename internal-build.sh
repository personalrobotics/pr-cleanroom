#!/bin/bash -e
SUDO='sudo -n'
CATKIN_BUILD='catkin build --no-status'

BUILD_PATH="/build"
OUTPUT_PATH="/test_results"

export SHELL="${SHELL=/bin/bash}"
export LD_PRELOAD="/usr/lib/libeatmydata/libeatmydata.so:${LD_PRELOAD}"

set -x

catkin init
catkin config --extend "/opt/ros/indigo" --cmake-args -DCMAKE_BUILD_TYPE=Release
cd src

find . -name manifest.xml -delete

${SUDO} apt-get update
rosdep update
rosdep install -y --ignore-src --rosdistro=indigo --from-paths .

${CATKIN_BUILD} -- "$@"
${CATKIN_BUILD} --no-deps --catkin-make-args tests -- "$@"
${CATKIN_BUILD} --no-deps --catkin-make-args run_tests -- "$@"

for package_name in $(ls "${BUILD_PATH}"); do
    if [ -d "${BUILD_PATH}/${package_name}/test_results/${package_name}" ]; then
        echo "Copying test results for package '${package_name}'."
        cp -r "${BUILD_PATH}/${package_name}/test_results/${package_name}" "${OUTPUT_PATH}/${package_name}"
    fi
done

cd ..
./view-all-results.sh "${OUTPUT_PATH}"

catkin_test_results /test_results
