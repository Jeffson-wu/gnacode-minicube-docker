FROM jenkins/jenkins:lts

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ENV USER_NAME $user
ENV JENKINS_HOME=/var/jenkins_home
ENV REF=/usr/share/jenkins/ref
ENV WORK_HOME=/home/$USER_NAME


#Install docker
USER root

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg-agent
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && usermod -aG docker ${USER_NAME}

VOLUME $JENKINS_HOME

#Modify jenkins user created in jenkins/jenkins:lts
RUN usermod -u $uid $USER_NAME
RUN groupmod -g $gid $USER_NAME

# Authorize SSH Host
ARG ssh_prv_key=""
ARG ssh_pub_key=""
RUN mkdir -p $WORK_HOME/.ssh

# Add the keys and set permissions
RUN echo "$ssh_prv_key" > $WORK_HOME/.ssh/id_rsa && \
    echo "$ssh_pub_key" > $WORK_HOME/.ssh/id_rsa.pub && \
    chmod 600 $WORK_HOME/.ssh/id_rsa && \
    chmod 600 $WORK_HOME/.ssh/id_rsa.pub

# Add known hosts
RUN ssh-keyscan -H bitbucket.org >> $WORK_HOME/.ssh/known_hosts
RUN ssh-keyscan -H github.com >> $WORK_HOME/.ssh/known_hosts

# Create folder for shared scripts
RUN mkdir -p $WORK_HOME/scripts

# jenkins user home folder is mapped to /var/jenkins_home, but to inject certificates, we use /home/jenkins/.ssh folder
RUN chown -R ${user}:${group} "$JENKINS_HOME" "$REF" "$WORK_HOME"

USER $USER_NAME