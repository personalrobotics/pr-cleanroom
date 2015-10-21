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

## Usage: wstool
The `run-wstool.sh` command builds and tests the repositories checked out by a
`.rosinstall` file. For example, this command tests our workspace for running
HERB in simulation:
```shell
$ ./run-wstool.sh https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/herb-minimal-sim.rosinstall
```
This command can simulatneously checkout multiple `.rosinstall` files. These
will be combined into a single `.rosinstall` file by sequentially running the
`wstool merge -y`. For example, this command simultaneously tests running both
ADA and HERB in simulation: 
```shell
$ ./run-wstool.sh https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/herb-minimal-sim.rosinstall \
                  https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/ada-sim.rosinstall
```

# Usage: distro
The `run-distro.sh` tests a single package (or list of packages) after building
them, and any dependencies, from source. The location of source dependencies
are checked out from the locations specified in a [distribution
file](http://www.ros.org/reps/rep-0143.html#distribution-file) to test a list
of packages.

For example, this command checks out the `herbpy` repository and its
dependencies from source and runs its tests:
```shell
$ ./run-distro.sh distro.yml --repository=herbpy
```

Some repositories contain more than one package. For example, the `comps`
repository contains `cbirrt2`, `generalik`, and `manipulation2`. This command
will build and test all three packages:
```shell
$ ./run-distro.sh distro.yml --repository=comps
```
It is also possible to test a subset of packages in the repository:
```shell
$ ./run-distro.sh distro.yml --package=cbirrt2 --package=generalik
```
