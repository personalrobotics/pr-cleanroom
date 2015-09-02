#!/bin/bash -e

is_running=$(docker inspect --format="{{ .State.Running }}" apt-cacher-ng)
if [ "${is_running}" != "true" ]; then
    echo "Building the apt-cache-ng Docker image."
    docker build -f Dockerfile_apt-cacher-ng -t apt-cacher-ng .

    echo "Starting apt-cacher-ng Docker container."
    docker rm apt-cacher-ng
    docker run -d --name=apt-cacher-ng apt-cacher-ng
else
    echo "Using existing apt-cacher-ng Docker container."
fi

echo "Building the client Docker image."
docker build -f Dockerfile_client -t pr-cleanroom .

echo "Starting the client Docker container."
echo docker run -it --link=apt-cacher-ng:apt-cacher-ng pr-cleanroom ./run-internal.sh $*
docker run -it --link=apt-cacher-ng:apt-cacher-ng pr-cleanroom ./run-internal.sh $*

# TODO: Copy the test results out of the Docker container.
