#!/bin/bash -e

if [ "$#" -ne 2 ]; then
    echo "error: incorrect number of arguments" 1>&2
    echo "usage: run-distro.sh <distribution.yaml> <repository>" 1>&2
    exit 1
fi

distribution_uri="$1"
repository="$2"
package_names="$(./internal-get-packages.py ${distribution_uri} ${repository})"

test_dir="$(mktemp -d)"
staging_dir="$(mktemp -d)"
cp "${distribution_uri}" "${staging_dir}/distribution.yml"

docker build -f Dockerfile_client -t pr-cleanroom .
docker run -it \
    --volume="${staging_dir}:/distribution"\
    --volume="${test_dir}:/test_results" \
    pr-cleanroom \
    bash -c "./internal-distro.py --workspace=src --repository ${repository} distribution/distribution.yml \
          && ./internal-build.sh ${package_names} \
          && ./internal-test.sh ${package_names}"

./view-all-results.sh "${test_dir}"
