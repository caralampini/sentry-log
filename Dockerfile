FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openssh-server gcc make sudo nano less tree procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

RUN useradd -m -s /bin/bash profesor && \
    echo 'profesor:password123' | chpasswd && \
    usermod -aG sudo profesor && \
    echo 'profesor ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/profesor && \
    chmod 0440 /etc/sudoers.d/profesor

COPY . /app
WORKDIR /app

RUN make build && \
    printf '%s\n' \
      'if [ -t 0 ] && [ -d /app ]; then' \
      '  cd /app || exit 1' \
      '  ./scripts/admin.sh' \
      '  exit 0' \
      'fi' \
      > /home/profesor/.bash_profile && \
    chown profesor:profesor /home/profesor/.bash_profile

EXPOSE 22
CMD ["/app/scripts/entrypoint.sh"]
