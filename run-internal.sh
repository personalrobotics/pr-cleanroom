#!/bin/bash -e

if [ "$#" -ne 1 ]; then
    echo 'error: Incorrect number of arguments.' 1>&2
    echo 'usage: ./run-internal.sh <rosinstall-uri>' 1>&2
    exit 1
fi

rosinstall_uri="$1"

# Clean up any previous runs.
# TODO: This is not sufficient because it does not remove installed packages.
rm -rf /home/ubuntu
mkdir -p /home/ubuntu
cd /home/ubuntu

# Create a Catkin workspace.
catkin init
catkin config --extend "/opt/ros/${ROS_DISTRO}" --cmake-args -DCMAKE_BUILD_TYPE=Release

# Checkout the .rosinstall file using wstool.
# TODO: Take the URI to the rosinstall file as an argument.
wstool init src
cd src
wget -O remote.rosinstall "${rosinstall_uri}"
wstool merge -y remote.rosinstall
# TODO: This is a hack until my changes to or_trajopt are merged.
wstool set -y or_trajopt -v bugfix/dependencies
wstool update

# Delete manifest.xml files because they confuse rosdep.
find . -name manifest.xml -delete

# Install dependencies using rosdep.
rosdep update
apt-get update
eatmydata rosdep install -y --ignore-src --from-paths .

# Build the packages (and unit tests) using catkin.
catkin build
catkin build --catkin-make-args tests

# Run the unit tests.
# TODO: Also check the test results using catkin_test_results.
catkin build --catkin-make-args run_tests
