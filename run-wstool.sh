#!/bin/bash -e

echo "Building the client Docker image."
docker build -f Dockerfile_client -t pr-cleanroom .

echo "Staging .rosinstall files."
staging_dir=$(mktemp -d)
staged_uris=()
for rosinstall_uri in "$@"; do
    rosinstall_name=$(basename "${rosinstall_uri}")
    staged_uris+=("file:///rosinstalls/${rosinstall_name}")

    echo "Staging '${rosinstall_uri}' => '${staging_dir}/${rosinstall_name}'"
    curl -o "${staging_dir}/${rosinstall_name}" "${rosinstall_uri}"
done

echo "Starting the client Docker container."
test_dir=$(mktemp -d)
docker run -it \
    --volume=${test_dir}:/test_results \
    --volume=${staging_dir}:/rosinstalls \
    pr-cleanroom \
    bash -c "./internal-wstool.sh ${staged_uris[@]} && ./internal-build.sh"

echo "Test results are in: ${test_dir}"
