#!/bin/bash -e
SUDO='sudo -n'
CATKIN_BUILD='catkin build --no-status -p 1 -i'

# Default options for 'catkin config'.
if [ -z ${CATKIN_CONFIG_OPTIONS+x} ]; then
  CATKIN_CONFIG_OPTIONS='-DCMAKE_BUILD_TYPE=Release'
fi

export SHELL="${SHELL=/bin/bash}"
export LD_PRELOAD="/usr/lib/libeatmydata/libeatmydata.so:${LD_PRELOAD}"

set -xe
catkin init
catkin config --extend /opt/ros/indigo ${CATKIN_CONFIG_OPTIONS}

# Delete 'manifest.xml' files because they confuse rosdep.
find src -name manifest.xml -delete

${SUDO} apt-get update
rosdep update
rosdep install -y --ignore-src --rosdistro=indigo --from-paths src

${CATKIN_BUILD} -p1 -- "$@"
