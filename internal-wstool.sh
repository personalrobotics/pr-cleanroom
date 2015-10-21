#!/bin/bash -e

echo "Merging .rosinstall files."
wstool init src
for rosinstall_uri in "$@"; do
    wstool merge -y -t src "${rosinstall_uri}"
done

echo "Checking out repositories."
git config --global credential.helper cache
wstool update -t src
