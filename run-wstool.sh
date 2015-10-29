#!/bin/bash -e

if [ "$#" -eq 0 ]; then
    echo "error: incorrect number of arguments" 1>&2
    echo "usage: run-wstool <file1.rosinstall> [<file2.rosinstall> [...]]" 1>&2
    exit 1
fi

test_dir=$(mktemp -d)
staging_dir=$(mktemp -d)

staged_uris=()
for rosinstall_uri in "$@"; do
    rosinstall_name=$(basename "${rosinstall_uri}")
    staged_uris+=("file:///rosinstalls/${rosinstall_name}")

    echo "Staging '${rosinstall_uri}' => '${staging_dir}/${rosinstall_name}'"
    #curl -o "${staging_dir}/${rosinstall_name}" "${rosinstall_uri}"
    cp "${rosinstall_uri}" "${staging_dir}/${rosinstall_name}"
done

docker build -f Dockerfile_client -t pr-cleanroom .
docker run -it \
    --volume=${test_dir}:/test_results \
    --volume=${staging_dir}:/rosinstalls \
    pr-cleanroom \
    bash -c "./internal-wstool.sh ${staged_uris[@]} && ./internal-build.sh \
          && ./internal-build.sh \
          && ./internal-test.sh"

./view-all-results.sh "${test_dir}"
