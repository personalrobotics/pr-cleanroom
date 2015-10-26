#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo 'error: incorrect number of arguments' 1>&2
    echo 'usage: view-all-results.py <results_path>' 1>&2
    exit 1
fi

input_dir="$1"
this_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

find "${input_dir}" -name "*.xml" -exec sh -c \
  "echo; echo 'File: {}'; '${this_directory}/view-results.py' {}" \;
