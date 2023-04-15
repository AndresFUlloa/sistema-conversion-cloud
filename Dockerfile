# base image
FROM python:3.10-alpine

# set working directory
RUN mkdir -p /code
WORKDIR /code

# psycopg2 dependencies
RUN apk update && apk upgrade
RUN apk add --no-cache build-base linux-headers postgresql-dev bind-tools
RUN apk add --no-cache --virtual .build-deps gcc musl-dev \
 && pip install cython && pip install psutil

# add requirements (to leverage Docker cache)
ADD requirements.txt ./requirements.txt

# install requirements
RUN pip install -r requirements.txt

# copy project
COPY compressor compressor/
COPY migrations migrations/
EXPOSE 5000