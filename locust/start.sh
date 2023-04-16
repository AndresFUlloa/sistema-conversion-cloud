#!/bin/bash
#
NAME="locust"

# --headless -u 100 -r 5
docker run --rm --name ${NAME} -p 8089:8089 -v $PWD:/mnt/locust locustio/locust -f /mnt/locust/locustfile.py