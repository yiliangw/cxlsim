#!/bin/bash

if [[ -z "$WD" ]]; then
    echo "WD is not set, using current directory"
    workdir=$(realpath .)
else
    workdir=$(realpath $WD)
fi

workdir_name=$(basename $workdir)
target_workdir="/workspace/${workdir_name}"

docker run \
    --user `id -u`:`id -g` \
    --mount type=bind,source=${workdir},target="${target_workdir}" \
    --volume /etc/group:/etc/group:ro \
    --volume /etc/passwd:/etc/passwd:ro \
    -it --rm -w"${target_workdir}" simbricks/simbricks-build:latest
