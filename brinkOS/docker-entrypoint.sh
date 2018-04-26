#!/bin/bash

if [ "$#" -eq 0 ]; then
	echo "Building brinkOS"
	cd /build/archiso || exit
	./build.sh -v &	
	wait
	echo "Exiting"
else
	exec "$@"
fi
