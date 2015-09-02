#!/bin/bash -e

# Clean up any previous workspace.
rm -rf /home/ubuntu
mkdir -p /home/ubuntu

# Add custom rosdep keys.
wget -P /etc/ros/rosdep/sources.list.d https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/rosdep/10-pr.list
rosdep update

# Create a Catkin workspace.
catkin init
catkin config --extend /opt/ros/${ROS_DISTRO} --cmake-args -DCMAKE_BUILD_TYPE=Release

# Use wstool to checkout our .rosinstall file.
# TODO: Take the URI to the rosinstall file as an argument.
wstool init src
cd src
wget -O remote.rosinstall https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/herb-minimal-sim.rosinstall
wstool merge -y remote.rosinstall
wstool set or_trajopt -v bugfix/dependencies
wstool update

# Delete manifest.xml files. These files confuse rosdep.
find . -name manifest.xml -delete

# Use rosdep to install dependencies.
apt-get update
eatmydata rosdep install -y --ignore-src --from-paths .

# Build the packages using catkin.
catkin build
