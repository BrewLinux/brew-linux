#!/bin/bash

./build.sh --arch "amd64 i386" -c http://localhost:3142 -m ftp.de.debian.org/debian -l ftp.de.debian.org/debian -s -t "brew.0.0.2" -p preseeds/basic.cfg 
