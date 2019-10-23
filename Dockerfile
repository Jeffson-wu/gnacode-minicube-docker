# Copyright 2019, Leonid Gonchar

# In any directory on the docker host, perform the following actions:
#   * Copy this Dockerfile in the directory.
#   * Create input and output directories: mkdir -p yocto/output yocto/input
#   * Build the Docker image with the following command:
#     Note, that ssh keys will be imported from local ~/.ssh
#     docker build --tag "minicube-image:latest" --no-cache --build-arg "host_uid=$(id -u)" --build-arg "host_gid=$(id -g)"  --build-arg ssh_prv_key="$(cat ~/.ssh/id_rsa)" --build-arg "ssh_pub_key=$(cat ~/.ssh/id_rsa.pub)" .
#   * Run the Docker image, which in turn runs the Yocto and which produces the Linux rootfs,
#     with the following command:
#     docker run -it --rm -v $PWD/yocto/output:/home/minicube/yocto/output minicube-image:latest
#     

# Use Ubuntu 16.04 LTS as the basis for the Docker image.
FROM ubuntu:16.04

# Install all the Linux packages required for Yocto builds. Note that the packages python3,
# tar, locales and cpio are not listed in the official Yocto documentation. The build, however,
# without them.
RUN apt-get update && apt-get -y install apt-utils gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
     xz-utils debianutils iputils-ping libsdl1.2-dev xterm tar locales repo sudo mc

# By default, Ubuntu uses dash as an alias for sh. Dash does not support the source command
# needed for setting up the build environment in CMD. Use bash as an alias for sh.
RUN rm /bin/sh && ln -s bash /bin/sh

# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV USER_NAME minicube
ENV PROJECT minicube

# The running container writes all the build artefacts to a host directory (outside the container).
# The container can only write files to host directories, if it uses the same user ID and
# group ID owning the host directories. The host_uid and group_uid are passed to the docker build
# command with the --build-arg option. By default, they are both 1001. The docker image creates
# a group with host_gid and a user with host_uid and adds the user to the group. The symbolic
# name of the group and user is minicube.
ARG host_uid=1001
ARG host_gid=1001
RUN groupadd -g $host_gid $USER_NAME && useradd -g $host_gid -m -s /bin/bash -u $host_uid $USER_NAME

# Perform the Yocto build as user minicube (not as root).
# NOTE: The USER command does not set the environment variable HOME.

# By default, docker runs as root. However, Yocto builds should not be run as root, but as a 
# normal user. Hence, we switch to the newly created user minicube.
USER $USER_NAME

# Authorize SSH Host
ARG ssh_prv_key=""
ARG ssh_pub_key=""
RUN mkdir -p /home/$USER_NAME/.ssh
RUN ssh-keyscan -H bitbucket.org >> /home/$USER_NAME/.ssh/known_hosts
RUN ssh-keyscan -H github.com >> /home/$USER_NAME/.ssh/known_hosts

# Add the keys and set permissions
RUN echo "$ssh_prv_key" > /home/$USER_NAME/.ssh/id_rsa && \
    echo "$ssh_pub_key" > /home/$USER_NAME/.ssh/id_rsa.pub && \
    chmod 600 /home/$USER_NAME/.ssh/id_rsa && \
    chmod 600 /home/$USER_NAME/.ssh/id_rsa.pub

# Create the directory structure for the Yocto build in the container. The lowest two directory
# levels must be the same as on the host.
ENV BUILD_DIR /home/$USER_NAME/yocto/input/$PROJECT
RUN mkdir -p $BUILD_DIR

# Fetch sources. Repo fetches base repository and downloads other source repositories performing sync command.
ARG branch="dev"
WORKDIR $BUILD_DIR
RUN repo init -u git@bitbucket.org:gnateam/gnacode-minicube-bsp-platform.git -b $branch
RUN repo sync

# Prepare Yocto's build environment. If TEMPLATECONF is set, the script oe-init-build-env will
# install the customised files bblayers.conf and local.conf. This script initialises the Yocto
# build environment. The bitbake command builds the rootfs for our embedded device.
ENV EULA=1
ENV MACHINE=imx28minicube
CMD cd $BUILD_DIR && source ./setup-environment build \
    && bitbake core-image-$PROJECT
