FROM jenkins/jenkins:lts

ENV USER_NAME jenkins

#Install docker
USER root

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg-agent
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && usermod -aG docker ${USER_NAME}

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

# Create folder for shared scripts
RUN mkdir -p /home/$USER_NAME/scripts

# jenkins user home folder is mapped to /var/jenkins_home, but to inject certificates, we use /home/jenkins/.ssh folder
RUN chown -R jenkins /home/jenkins

USER $USER_NAME