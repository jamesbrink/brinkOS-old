#!/bin/bash

if [ "$#" -eq 0 ]; then
	echo "Building brinkOS"
	cd /build/archlive/ || exit
	time ./build.sh -v -N brinkOS -o /iso
	echo "Exiting"
else
	exec "$@"
fi
