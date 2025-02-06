#!/bin/bash

set -e

KERNEL_PARAM="guest_input_tar"

INPUT_TAR_DEV=$(cat /proc/cmdline | sed -n 's/.*simbricks_guest_input=\([^ ]*\).*/\1/p')

fname=$(basename $0)

if [ -z "${INPUT_TAR_DEV}" ]; then
    echo "${fname}: \`simbricks_guest_input\` not found. Exit."
    exit 0
fi

# check whether /dev/sdb exists
if [ ! -e "$INPUT_TAR_DEV" ]; then
    echo "${fname}: Input tar not found (${INPUT_TAR_DEV}). Exit."
    exit 0
fi

# check whether /dev/sdb is a tar file and there is a guest/run.sh inside
if ! tar tf /dev/sdb | grep -q guest/run.sh; then
    echo "${fname}: ${INPUT_TAR_DEV} is not a valid input tar. Exit."
    exit 0
fi

echo "${fname}: Processing input tar ${INPUT_TAR_DEV}..."
cd /tmp
tar xf ${INPUT_TAR_DEV}
cd guest
echo "${fname}: Running workload..."
./run.sh
