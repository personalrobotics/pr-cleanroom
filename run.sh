#!/bin/bash -e

# TODO: Automatically start the apt-cache container.
# TODO: Is it safe to hard-code the container name here?
docker exec -it prcleanroom_client_1 ./run-internal.sh $*

# TODO: Copy the test results out of the Docker container.
