#!/bin/bash

ps -ef |grep "jenkins.war" | awk '{print \$2}' | xargs kill

nohup ./jenkins.sh > jenkins-restart.out&
