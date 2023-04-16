#!/bin/bash
#
NAME="locust"

docker run --rm --name ${NAME} -p 8089:8089 -v $PWD:/mnt/locust locustio/locust -f /mnt/locust/locustfile.py