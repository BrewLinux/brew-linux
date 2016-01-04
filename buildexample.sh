#!/bin/bash

./build.sh --arch "amd64 i386" -c http://192.168.10.43:3142 -m ftp.de.debian.org/debian -l ftp.de.debian.org/debian -s -t "brew.0.0.2" -p preseeds/basic.cfg 
