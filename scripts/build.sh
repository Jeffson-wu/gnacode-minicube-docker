#!/bin/sh

BRANCH=dev
OUTPUT_DIR=/home/minicube/output

mkdir -p $(pwd)/output

docker run -it --rm -v $(pwd)/output:${OUTPUT_DIR} biovices/yocto:latest /bin/sh -c " \
    export EULA=1 && \
    export MACHINE=imx28minicube && \
    repo init -u git@bitbucket.org:gnateam/gnacode-minicube-bsp-platform.git -b ${BRANCH} && \
    repo sync && \
    source ./setup-environment build && \
    bitbake core-image-minicube && \
    rm -rf ${OUTPUT_DIR}/* && \
    cp -r \${BUILD_DIR}/build/tmp/deploy/images ${OUTPUT_DIR}
"