FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openssh-server gcc make \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd
# Nota: La contraseña debería ser pasada por build-arg o manejada de forma segura
RUN useradd -m -s /bin/bash profesor && \
    echo 'profesor:password123' | chpasswd 

COPY . /app
WORKDIR /app

# Solo compila si existe un Makefile
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
