#!/bin/bash
service docker stop
nohup docker -d --insecure-registry 10.37.0.72:5000 > docker-daemon.log 2>&1 &
