#!/bin/bash

# read from standard input and convert to array
mapfile -t commits <<< `cat`
# reverse commits to be newest first
commits=($(printf '%s\n' "${commits[@]}" | tac))
command=$@

for commit in "${commits[@]}"; do
    git checkout ${commit} > /dev/null 2>&1
    echo "Executing \"${command}\" at ${commit}"
    eval $command
done