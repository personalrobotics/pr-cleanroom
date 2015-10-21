#!/bin/bash -e

distribution_uri="$1"
distribution_args="${@:2}"

echo "Staging distribution file."
staging_dir=$(mktemp -d)
cp "${distribution_uri}" "${staging_dir}/distribution.yml"

echo "Building the client Docker image."
docker build -f Dockerfile_client -t pr-cleanroom .

echo "Starting the client Docker container."
test_dir=$(mktemp -d)
docker run -it \
    --volume=${staging_dir}:/distribution\
    --volume=${test_dir}:/test_results \
    pr-cleanroom \
    bash -c "./internal-distro.py --workspace=src ${distribution_args} distribution/distribution.yml && ./internal-build.sh"

echo "Test results are in: ${test_dir}"
