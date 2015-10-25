#!/bin/bash -e

distribution_uri="$1"
repository="$2"
package_names="$(./internal-get-packages.py ${distribution_uri} ${repository})"

staging_dir=$(mktemp -d)
cp "${distribution_uri}" "${staging_dir}/distribution.yml"

docker build -f Dockerfile_client -t pr-cleanroom .

test_dir=$(mktemp -d)
docker run -it \
    --volume=${staging_dir}:/distribution\
    --volume=${test_dir}:/test_results \
    pr-cleanroom \
    bash -c "./internal-distro.py --workspace=src --repository ${repository} distribution/distribution.yml && ./internal-build.sh ${package_names}"

echo "Test results are in: ${test_dir}"
