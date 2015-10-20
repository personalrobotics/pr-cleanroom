# pr-cleanroom
pr-cleanroom automates the testing of Personal Robotics Lab packages in a clean environment. This package operates on `.rosinstall` files, typically downloaded from the [`pr-rosinstalls` repository](https://github.com/personalrobotics/pr-rosinstalls), and:

1. Checks out the input `.rosinstall` file(s)
2. Installs system dependencies using `rosdep`
3. Builds the workspace using `catkin build`
4. Runs unit tests

## Dependencies
This package uses Docker to create a clean build environment. Follow [these
instructions](https://docs.docker.com/installation/ubuntulinux/#installation)
to install Docker on Ubuntu. The short version is:

```shell
$ sudo apt-get update
$ sudo apt-get install curl
$ curl -sSL https://get.docker.com/gpg | sudo apt-key add -
$ curl -sSL https://get.docker.com/ | sh
$ sudo usermod -aG docker <YOUR_USER_NAME> # optional
```

## Usage
This utility operates `.rosinstall` files using `wstool`, which supports both local paths and `http(s)` URIs as input. For example, this command tests our workspace for running HERB in simulation
```shell
$ ./run.sh https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/herb-minimal-sim.rosinstall
```

You can also pass multiple `.rosinstall` files. These will be combined into a single `.rosinstall` file by sequentially running the `wstool merge -y`. For example, simultaneously tests running both ADA and HERB in simulation: 
```shell
$ ./run.sh https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/herb-minimal-sim.rosinstall https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/ada-sim.rosinstall
```
