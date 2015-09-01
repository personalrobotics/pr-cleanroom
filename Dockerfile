FROM ubuntu:14.04
MAINTAINER Michael Koval <mkoval@cs.cmu.edu>
ENV DEBIAN_FRONTEND noninteractive

# Create non-root user 'ubuntu' with sudo access.
RUN groupadd ubuntu
RUN useradd -g ubuntu -G sudo ubuntu
RUN echo ubuntu:u | chpasswd
RUN cp -a /etc/skel /home/ubuntu
RUN chown -R ubuntu:ubuntu /home/ubuntu
RUN echo "ubuntu ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ubuntu

# Set up Perl locales to avoid tons of warnings.
RUN apt-get -qq update && apt-get -qq install locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen

# Set environment variable that wstool and rosdep expect.
# TODO: Template ROS_DISTRO
ENV TERM xterm
ENV SHELL /bin/bash
ENV LANG en_US.UTF-8
ENV LANGUAGE=en_US
ENV LC_ALL en_US.UTF-8
ENV ROS_DISTRO indigo

# Install bare-bones system utilities.
RUN apt-get -qq update && apt-get -qq install wget

# Add ROS APT repository.
RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list
RUN wget -q https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -O - | apt-key add -

# Install upstream APT dependencies. Also initialize rosdep, which is only
# necessary once immediately after installation. 
RUN apt-get -qq update && apt-get -qq install ros-${ROS_DISTRO}-ros-base python-catkin-tools python-rosdep python-pip python-wstool wget git mercurial subversion
RUN rosdep init

# Create a workspace.
USER ubuntu
WORKDIR /home/ubuntu
RUN mkdir src
RUN wstool init src

# Manually install OpenRAVE (this is a hack).
# TODO: Install OpenRAVE from a .deb package.
WORKDIR /home/ubuntu/src
RUN echo 5
RUN wstool set -y openrave https://github.com/personalrobotics/openrave.git --git
RUN wstool update openrave
RUN wget -P openrave/ https://gist.githubusercontent.com/mkoval/495b40fe828a727987e2/raw/539e5c92babb89ac543cdac49c5276b48d59af8c/package.xml

# Use wstool to checkout our .rosinstall file.
# TODO: Template the URI to the rosinstall file.
RUN echo 8
RUN wget -O remote.rosinstall https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/herb-minimal-sim.rosinstall
RUN wstool merge -y remote.rosinstall
RUN wstool update

# Delete manifest.xml files. These files confuse rosdep.
RUN find . -name manifest.xml -delete

# Add custom rosdep keys.
USER root
RUN wget -P /etc/ros/rosdep/sources.list.d https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/rosdep/10-pr.list
USER ubuntu

# Use rosdep to install dependencies.
RUN rosdep update
RUN rosdep install --from-paths . --ignore-src -y

#
## Build the packages using catkin.
#USER ubuntu
#WORKDIR /home/ubuntu
#RUN catkin init
#RUN catkin config --extend /opt/ros/${ROS_DISTRO} --cmake-args -DCMAKE_BUILD_TYPE=Release
