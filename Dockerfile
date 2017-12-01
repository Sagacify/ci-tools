FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /opt

RUN apt-get -q=2 update
RUN apt-get -q=2 -y install curl unzip man
