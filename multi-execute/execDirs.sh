#!/bin/bash

dirs=`ls -d */`
command=$@

for dir in $dirs; do
    cd $dir
    echo "==========Executing \"$command\" in \"$dir\"=========="
    eval $command
    echo ""
    cd ..
done