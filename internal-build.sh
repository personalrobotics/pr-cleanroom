#!/bin/bash
SUDO='sudo -n'
CATKIN_BUILD='catkin build --no-status -p 1 -i'
LIBEATMYDATA_PATH=$(find /usr/lib/ -name libeatmydata.so)

# Default options for 'catkin config'.
if [ -z ${CATKIN_CONFIG_OPTIONS+x} ]; then
  CATKIN_CONFIG_OPTIONS='-DCMAKE_BUILD_TYPE=Release'
fi

if [ `lsb_release -sc` = "trusty" ]; then
  ROS_DISTRO='indigo'
elif [ `lsb_release -sc` = "xenial" ]; then
  ROS_DISTRO='kinetic'
else
  echo "error: Ubuntu $(lsb_release -sc) is not supported."
  exit 1
fi

export SHELL="${SHELL=/bin/bash}"
export LD_PRELOAD="${LIBEATMYDATA_PATH}:${LD_PRELOAD}"

set -xe
catkin init
catkin config --extend /opt/ros/${ROS_DISTRO} ${CATKIN_CONFIG_OPTIONS}

# Delete 'manifest.xml' files because they confuse rosdep.
find src -name manifest.xml -delete

${SUDO} apt-get update
rosdep update
rosdep install -y --ignore-src --rosdistro=${ROS_DISTRO} --from-paths src

${CATKIN_BUILD} -p1 -- "$@"
