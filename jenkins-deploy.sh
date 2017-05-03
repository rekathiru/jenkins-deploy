#!/bin/bash

apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

apt-get update

apt-get install openjdk-7-jdk -y

apt-get update

apt-get install unzip

export JENKINS_HOME=/var/jenkins_home
export JENKINS_SLAVE_AGENT_PORT=50000

user=jenkins
group=jenkins
uid=1100
gid=1100

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container, 
# ensure you use the same uid
groupadd -g ${gid} ${group} && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}


# `/usr/share/jenkins/ref/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.

mkdir -p /usr/share/jenkins/ref/init.groovy.d

# jenkins version being bundled in this docker image
export JENKINS_VERSION=2.46.2

# jenkins.war checksum, download will be validated using it
JENKINS_SHA=aa7f243a4c84d3d6cfb99a218950b8f7b926af7aa2570b0e1707279d464472c7

# Can be used to customize where jenkins.war get downloaded from
JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/2.46.2/jenkins-war-2.46.2.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum 
# see https://github.com/docker/docker/issues/8331
curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

export JENKINS_UC=https://updates.jenkins.io
chown -R ${user} /usr/share/jenkins/ref
chown -R ${user} ${JENKINS_HOME}

export COPY_REFERENCE_FILE_LOG=${JENKINS_HOME}/copy_reference_file.log

sudo su jenkins
pushd $JENKINS_HOME

git clone https://github.com/rekathiru/jenkins-deploy.git

cp jenkins-deploy/jenkins-support /usr/local/bin/jenkins-support

cp jenkins-deploy/install-plugins.sh .

cp jenkins-deploy/jenkins-deploy.sh .

cp jenkins-deploy/jenkins.sh .

mkdir -p .jenkins/jobs

cp -r jenkins-deploy/jenkins/* .jenkins/

sh install-plugins.sh github maven-plugin

cp /usr/share/jenkins/ref/plugins/* .jenkins/plugins/

sh jenkins.sh

wget http://localhost:8080/jnlpJars/jenkins-cli.jar

echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("user1", "abc123")' | java -jar jenkins-cli.jar -auth admin:12be9ffeb4dc40a483a7ad014db493c0 -s http://localhost:8080/ groovy =
