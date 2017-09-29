#!/bin/bash -e
APTGET='apt-get -qqy'
CURL='curl -sS'
SUDO='sudo -n'

set -x

# Add the ROS apt repository.
if [ ! -f /etc/apt/sources.list.d/ros-latest.list ]; then
  ${SUDO} apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116
  ${SUDO} sh -c 'echo "deb http://packages.ros.org/ros/ubuntu trusty main" > /etc/apt/sources.list.d/ros-latest.list'
fi

# Add the DART apt repository.
${SUDO} apt-add-repository -y ppa:libccd-debs
${SUDO} apt-add-repository -y ppa:fcl-debs
${SUDO} apt-add-repository -y ppa:dartsim
${SUDO} add-apt-repository -y ppa:personalrobotics/ppa

# Install ROS build tools.
${SUDO} ${APTGET} update
${SUDO} ${APTGET} install --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  eatmydata \
  git \
  mercurial \
  python-catkin-tools \
  python-pip \
  python-rosdep \
  python-rosinstall \
  python-wstool \
  python-vcstools \
  ros-indigo-ros-core \
  subversion

# Setup rosdep with our custom keys.
${SUDO} rosdep init || true
${SUDO} ${CURL} -o '/etc/ros/rosdep/sources.list.d/10-pr.list' 'https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/rosdep/10-pr.list'
