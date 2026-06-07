FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openssh-server gcc make \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

RUN useradd -m -s /bin/bash profesor && \
    echo 'profesor:password123' | chpasswd 

COPY . /app
WORKDIR /app

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
