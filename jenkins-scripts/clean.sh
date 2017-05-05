#!/bin/bash

ps -ef |grep "jenkins.war" | awk '{print \$2}' | xargs kill

rm -rf /var/jenkins_home

rm -rf /usr/share/jenkins

