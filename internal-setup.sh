#!/bin/bash -e
APTGET='apt-get -qqy'
CURL='curl -sS'
SUDO='sudo -n'
if [ `lsb_release -sc` = "trusty" ]; then
  ROS_DISTRO='indigo'
elif [ `lsb_release -sc` = "xenial" ]; then
  ROS_DISTRO='kinetic'
elif [ `lsb_release -sc` = "bionic" ]; then
  ROS_DISTRO='melodic'
elif [ `lsb_release -sc` = "focal" ]; then
  ROS_DISTRO='noetic'
else
  echo "error: Ubuntu $(lsb_release -sc) is not supported."
  exit 1
fi

set -x

# Add the ROS apt repository.
if [ ! -f /etc/apt/sources.list.d/ros-latest.list ]; then
  ${SUDO} sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  ${SUDO} apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
fi

# Add necessary apt repositories.
if [ `lsb_release -cs` = "trusty" ]; then
  ${SUDO} apt-add-repository -y ppa:libccd-debs
  ${SUDO} apt-add-repository -y ppa:fcl-debs
fi
${SUDO} apt-add-repository -y ppa:dartsim
${SUDO} add-apt-repository -y ppa:personalrobotics/ppa

# Install ROS build tools.
${SUDO} ${APTGET} update

# Upgrade to dpkg >= 1.17.5ubuntu5.8, which fixes
# https://bugs.launchpad.net/ubuntu/+source/dpkg/+bug/1730627
# (https://github.com/travis-ci/travis-ci/issues/9361)
${SUDO} ${APTGET} install dpkg

${SUDO} ${APTGET} install --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  doxygen \
  eatmydata \
  git \
  mercurial \
  ros-${ROS_DISTRO}-ros-core \
  subversion

if [ `lsb_release -sc` = "focal" ]; then
  echo "Set disable_coredump false" >> /etc/sudo.conf  # https://github.com/sudo-project/sudo/issues/42
  ${SUDO} ${APTGET} install --no-install-recommends \
    python3-catkin-tools \
    python3-pip \
    python3-rosdep \
    python3-rosinstall \
    python3-wstool \
    python3-vcstools
else
  ${SUDO} ${APTGET} install --no-install-recommends \
    python-catkin-tools \
    python-pip \
    python-rosdep \
    python-rosinstall \
    python-wstool \
    python-vcstools
fi

# Setup rosdep with our custom keys.
${SUDO} rosdep init || true
${SUDO} ${CURL} -o '/etc/ros/rosdep/sources.list.d/10-pr.list' 'https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/rosdep/10-pr.list'
