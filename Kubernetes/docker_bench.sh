#!/bin/bash

if [ ! -d docker-bench-security ]; then 
    git clone https://github.com/docker/docker-bench-security.git
fi
cd docker-bench-security
sudo sh ./docker-bench-security.sh
