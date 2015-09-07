#!/bin/bash -e

is_running=$(docker inspect --format="{{ .State.Running }}" apt-cacher-ng)
if [ "${is_running}" != "true" ]; then
    echo "Building the apt-cache-ng Docker image."
    docker build -f Dockerfile_apt-cacher-ng -t apt-cacher-ng .

    echo "Starting the apt-cacher-ng Docker container."
    docker rm apt-cacher-ng
    docker run -d --name=apt-cacher-ng apt-cacher-ng
else
    echo "Using existing apt-cacher-ng Docker container."
fi

echo "Building the client Docker image."
docker build -f Dockerfile_client -t pr-cleanroom .

echo "Staging .rosinstall files."
staging_dir=$(mktemp -d)
staged_uris=()
for rosinstall_uri in "$@"; do
    rosinstall_name=$(basename "${rosinstall_uri}")
    staged_uris+=("file:///rosinstalls/${rosinstall_name}")

    echo "Staging '${rosinstall_uri}' => '{staging_dir}/${rosinstall_name}'"
    curl -o "${staging_dir}/${rosinstall_name}" "${rosinstall_uri}"
done

echo "Starting the client Docker container."
docker run -it \
    --link=apt-cacher-ng:apt-cacher-ng \
    --volume=${staging_dir}:/rosinstalls \
    pr-cleanroom \
    ./run-internal.sh ${staged_uris[@]}

# TODO: Copy the test results out of the Docker container.
# TODO: Check the test results using catkin_test_results.
