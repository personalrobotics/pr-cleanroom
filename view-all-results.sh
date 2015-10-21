#!/bin/bash
input_dir="$1"
find "${input_dir}" -name "*.xml" -exec sh -c 'echo; echo "File: {}"; ./view-results.py {}' \;
