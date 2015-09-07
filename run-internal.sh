#!/bin/bash -e

echo "Creating Catkin workspace."
wstool init src
catkin init
catkin config --extend "/opt/ros/${ROS_DISTRO}" --cmake-args -DCMAKE_BUILD_TYPE=Release
cd src

echo "Merging .rosinstall files."
for rosinstall_uri in "$@"; do
    wstool merge -y "${rosinstall_uri}"
done

echo "Checking out repositories."
git config --global credential.helper cache
wstool update

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
