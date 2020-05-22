#!/bin/bash

# Pull current container info and recreate with new image
for cont in $(docker ps -a --format '{{.Names}}') ; do
	if [ $(docker inspect -f '{{eq "/matrix/nodeConfig.sh" .Path}}' $cont) = "true" ]; then
		echo "farts"
	fi
done
