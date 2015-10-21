#!/bin/bash -e

echo "Creating Catkin workspace."
catkin init
catkin config --extend "/opt/ros/${ROS_DISTRO}" --cmake-args -DCMAKE_BUILD_TYPE=Release
cd src

# Delete manifest.xml files because they confuse rosdep.
echo "Deleting 'manifest.xml' files."
find . -name manifest.xml -delete

# Install dependencies using rosdep. 
echo "Installing dependencies."
rosdep update
apt-get update
eatmydata rosdep install -y --ignore-src --from-paths .

echo "Building."
catkin build

echo "Building tests."
catkin build --catkin-make-args tests

echo "Running tests."
catkin build --catkin-make-args run_tests

echo "Copying test results."
build_path="/build"
output_path="/test_results"

for package_name in $(ls "${build_path}"); do
    if [ -d "${build_path}/${package_name}/test_results/${package_name}" ]; then
        echo "Copying test results for package '${package_name}'."
        cp -r "${build_path}/${package_name}/test_results/${package_name}" "${output_path}/${package_name}"
    fi
done

echo "Displaying test results:"
cd ..
./view-all-results.sh "${output_path}"

# Generate a non-zero return code if any of the tests failed.
catkin_test_results /test_results
