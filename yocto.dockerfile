# Copyright 2019, Leonid Gonchar

# In any directory on the docker host, perform the following actions:
#   * Copy this Dockerfile in the directory.
#   * Create output directory: mkdir -p ./output
#   * Build the Docker image with the following command:
#     Note, that ssh keys will be imported from local ~/.ssh
#     docker build --tag "minicube-image:latest" --no-cache --build-arg "uid=$(id -u)" --build-arg "gid=$(id -g)"  --build-arg ssh_prv_key="$(cat ~/.ssh/id_rsa)" --build-arg "ssh_pub_key=$(cat ~/.ssh/id_rsa.pub)" .
#   * Run the Docker image, which in turn runs the Yocto and which produces the Linux rootfs,
#     with the following command:
#     docker run -it --rm -v $PWD/output:/home/minicube/output minicube-image:latest
#

# Use Ubuntu 16.04 LTS as the basis for the Docker image.
FROM ubuntu:16.04


RUN apt-get update && apt-get install -y software-properties-common
# Added repository for python 3.6
RUN add-apt-repository ppa:deadsnakes/ppa
# Added repository for latest git
RUN add-apt-repository ppa:git-core/ppa
# Install all the Linux packages required for Yocto builds. Note that the packages python3,
# tar, locales and cpio are not listed in the official Yocto documentation. The build, however,
# without them.
RUN  apt-get update && apt-get -y install apt-utils gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python python3.6 \
     xz-utils debianutils iputils-ping libsdl1.2-dev xterm tar locales sudo mc \
     gcc-arm-none-eabi binutils-arm-none-eabi gdb-arm-none-eabi openocd curl

RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/bin/repo && chmod +x /usr/bin/repo

# By default, Ubuntu uses dash as an alias for sh. Dash does not support the source command
# needed for setting up the build environment in CMD. Use bash as an alias for sh.
RUN rm /bin/sh && ln -s bash /bin/sh

# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV USER_NAME yocto

# The running container writes all the build artefacts to a host directory (outside the container).
# The container can only write files to host directories, if it uses the same user ID and
# group ID owning the host directories. The uid and group_uid are passed to the docker build
# command with the --build-arg option. By default, they are both 1001. The docker image creates
# a group with gid and a user with uid and adds the user to the group. The symbolic
# name of the group and user is minicube.
ARG uid=1000
ARG gid=1000
# minicube user password is set to 'minicube'
RUN groupadd -g $gid $USER_NAME && useradd -g $gid -G sudo -m -s /bin/bash -u $uid \
 -p '$6$ldfK792N$TLYHKs4tIITJKoOB./U/8JUOmvfSyQHr/CkoSHyATSzPDaxne1Z.X6W/mf96iAqg6NcmdFS0iLri3ah4FvNHG.' $USER_NAME

# Perform the Yocto build as user minicube (not as root).
# NOTE: The USER command does not set the environment variable HOME.

# By default, docker runs as root. However, Yocto builds should not be run as root, but as a 
# normal user. Hence, we switch to the newly created user minicube.
USER $USER_NAME

# Authorize SSH Host
ARG ssh_prv_key=""
ARG ssh_pub_key=""
RUN mkdir -p /home/$USER_NAME/.ssh

# Add the keys and set permissions
RUN echo "$ssh_prv_key" > /home/$USER_NAME/.ssh/id_rsa && \
    echo "$ssh_pub_key" > /home/$USER_NAME/.ssh/id_rsa.pub && \
    chmod 600 /home/$USER_NAME/.ssh/id_rsa && \
    chmod 600 /home/$USER_NAME/.ssh/id_rsa.pub

# Add known hosts
RUN ssh-keyscan -H bitbucket.org >> /home/$USER_NAME/.ssh/known_hosts
RUN ssh-keyscan -H github.com >> /home/$USER_NAME/.ssh/known_hosts

# Create the directory structure for the Yocto build in the container. The lowest two directory
# levels must be the same as on the host.
ENV BUILD_DIR /home/$USER_NAME/bld
ENV OUTPUT_DIR /home/$USER_NAME/output
RUN mkdir -p $BUILD_DIR $OUTPUT_DIR

# Configure git
RUN git config --global user.email "developer@biovsystems.com"
RUN git config --global user.name "developer"
RUN git config --global color.ui always
RUN git config --global color.branch always
RUN git config --global color.status always

WORKDIR $BUILD_DIR

# Fetch sources. Repo fetches base repository and downloads other source repositories performing sync command.
# Prepare Yocto's build environment. If TEMPLATECONF is set, the script oe-init-build-env will
# install the customised files bblayers.conf and local.conf. This script initialises the Yocto
# build environment. The bitbake command builds the rootfs for our embedded device.
# ENV EULA=1
# ENV MACHINE=imx28minicube
# CMD repo init -u git@bitbucket.org:gnateam/gnacode-minicube-bsp-platform.git -b dev && repo sync && && source ./setup-environment build \
#    && bitbake core-image-$PROJECT \
#    && rm -rf $OUTPUT_DIR/* && cp -r $BUILD_DIR/build/tmp/deploy/images $OUTPUT_DIR/
#CMD cd $BUILD_DIR && source ./setup-environment build \
#    && bitbake core-image-$PROJECT \
#    && rm -rf $OUTPUT_DIR/* && cp -r $BUILD_DIR/build/tmp/deploy/images $OUTPUT_DIR/
