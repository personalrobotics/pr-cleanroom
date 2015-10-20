# pr-cleanroom
Utilities for testing the installation of the Personal Robotics Lab software in a clean environment.

## Docker Installation
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
```shell
$ ./run.sh https://example.com/test1.rosinstall https://example.com/test2.rosinstall
```
