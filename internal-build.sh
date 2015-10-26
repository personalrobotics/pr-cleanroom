#!/bin/bash
SUDO='sudo -n'
CATKIN_BUILD='catkin build --no-status'

if [ "$#" -eq 0 ]; then
    echo 'error: no packages were specified' 1>&2
    echo 'usage: internal-build.sh package1 [package2 [...]]' 1>&2
    exit 1
fi

export SHELL="${SHELL=/bin/bash}"
export LD_PRELOAD="/usr/lib/libeatmydata/libeatmydata.so:${LD_PRELOAD}"

set -x
catkin init
catkin config --extend /opt/ros/indigo --cmake-args -DCMAKE_BUILD_TYPE=Release

# Delete 'manifest.xml' files because they confuse rosdep.
find src -name manifest.xml -delete

${SUDO} apt-get update
rosdep update
rosdep install -y --ignore-src --rosdistro=indigo --from-paths src

${CATKIN_BUILD} -- "$@"
