#!/bin/sh


if [ -z "${BRANCH}" ]; then 
    BRANCH=dev
fi
if [ -z "$BUILD_VARIANT" ]; then 
    BUILD_VARIANT=develop
fi
SET_BUILD_VARIANT="BUILD_VARIANT = \\\"${BUILD_VARIANT}\\\""
OUTPUT_DIR=$(pwd)/output

mkdir -p ${OUTPUT_DIR}

docker run -i --rm -v jenkins-data:/var/jenkins_home biovices/yocto:latest /bin/sh -c " \
    export EULA=1 && \
    export MACHINE=imx28minicube && \
    repo init -u git@bitbucket.org:gnateam/gnacode-minicube-bsp-platform.git -b ${BRANCH} && \
    repo sync && \
    source ./setup-environment build && \
    cd ./.. && \
    echo ${SET_BUILD_VARIANT} >> ./build/conf/local.conf  && \
    source ./setup-environment build && \
    bitbake core-image-minicube && \
    rm -rf ${OUTPUT_DIR}/* && \
    cp -r \${BUILD_DIR}/build/tmp/deploy/images/imx28minicube/* ${OUTPUT_DIR}
"
