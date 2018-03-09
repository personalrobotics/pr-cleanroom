#!/bin/bash -e
APTGET='apt-get -qqy'
CURL='curl -sS'
SUDO='sudo -n'
if [ `lsb_release -cs` = "trusty" ]; then
  ROS_DISTRO='indigo'
elif [ `lsb_release -cs` = "xenial" ]; then
  ROS_DISTRO='lunar'
fi

set -x

# Add the ROS apt repository.
if [ ! -f /etc/apt/sources.list.d/ros-latest.list ]; then
  ${SUDO} sh -c 'echo "deb http://packages.ros.org/ros/ubuntu ${ROS_DISTRO} main" > /etc/apt/sources.list.d/ros-latest.list'
  ${SUDO} apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
fi

# For test
cat /etc/apt/sources.list.d/ros-latest.list

# Add necessary apt repositories.
if [ `lsb_release -cs` = "trusty" ]; then
  ${SUDO} apt-add-repository -y ppa:libccd-debs
  ${SUDO} apt-add-repository -y ppa:fcl-debs
fi
${SUDO} apt-add-repository -y ppa:dartsim
${SUDO} add-apt-repository -y ppa:personalrobotics/ppa

# Install ROS build tools.
${SUDO} ${APTGET} update
${SUDO} ${APTGET} install --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  doxygen \
  eatmydata \
  git \
  mercurial \
  python-catkin-tools \
  python-pip \
  python-rosdep \
  python-rosinstall \
  python-wstool \
  python-vcstools \
  ros-${ROS_DISTRO}-ros-core \
  subversion

# Setup rosdep with our custom keys.
${SUDO} rosdep init || true
${SUDO} ${CURL} -o '/etc/ros/rosdep/sources.list.d/10-pr.list' 'https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/rosdep/10-pr.list'
