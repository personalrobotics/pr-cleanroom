#!/bin/bash -ex

# Add the ROS apt repository.
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116
echo 'deb http://packages.ros.org/ros/ubuntu trusty main' > /etc/apt/sources.list.d/ros-latest.list

# Install ROS build tools.
apt-get -qq update
apt-get -qqy install --no-install-recommends \
  ca-certificates \
  curl \
  eatmydata \
  git \
  mercurial \
  python-catkin-tools \
  python-rosdep \
  python-rosinstall \
  python-wstool \
  subversion

# Add the PR apt repository.
curl https://www.personalrobotics.ri.cmu.edu/files/personalrobotics.gpg | sudo apt-key add -
echo 'deb http://packages.personalrobotics.ri.cmu.edu/public trusty main' > /etc/apt/sources.list.d/personalrobotics.list

# Setup rosdep with our custom keys.
rosdep init
curl -o /etc/ros/rosdep/sources.list.d/10-pr.list https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/rosdep/10-pr.list
