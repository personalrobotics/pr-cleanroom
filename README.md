# pr-cleanroom
Utilities for testing the installation of the Personal Robotics Lab software in a clean environment.

## Dependencies
### Docker
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

At this point you will need to log out and log back in.

## Docker Compose
This package uses [Docker Compose](https://docs.docker.com/compose/) to manage
building and running multiple Docker containers. Follow [these
instructions](https://docs.docker.com/compose/install/#install-docker-compose)
to install Docker Compose on Ubuntu. The short version is:

```shell
$ curl -L https://github.com/docker/compose/releases/download/VERSION_NUM/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
```

## Usage
First, use Docker Compose to launch the `docker-compose.yml` file:
```shell
$ docker-compose build
$ docker-compose up
```
Then, in a different terminal window, run a test on a `.rosinstall` file:
```shell
$ ./run-rosinstall.sh https://raw.githubusercontent.com/personalrobotics/pr-rosinstalls/master/rosdep/10-pr.list
```

## Known Issues

- The Docker container must be restarted after each time the
  `build-rosinstall.sh` script is run, otherwise dependencies may persist
  between queries.
- The `build-rosinstall.sh` script is not re-entrant.

