#!/bin/bash -ex
build_path="/build"
output_path="/test_results"

catkin init
catkin config --extend "/opt/ros/${ROS_DISTRO}" --cmake-args -DCMAKE_BUILD_TYPE=Release
cd src

find . -name manifest.xml -delete

apt-get update
rosdep update
rosdep install -y --ignore-src --from-paths .

catkin build
catkin build --catkin-make-args tests
catkin build --catkin-make-args run_tests

for package_name in $(ls "${build_path}"); do
    if [ -d "${build_path}/${package_name}/test_results/${package_name}" ]; then
        echo "Copying test results for package '${package_name}'."
        cp -r "${build_path}/${package_name}/test_results/${package_name}" "${output_path}/${package_name}"
    fi
done

cd ..
./view-all-results.sh "${output_path}"

catkin_test_results /test_results
