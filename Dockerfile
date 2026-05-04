FROM cruizba/ubuntu-dind:noble-latest AS builder

ARG RUNNER_VERSION="2.334.0"

WORKDIR /build

COPY start.sh /opt/start.sh

ADD https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz /build/

RUN apt-get update &&\
    apt-get -y install curl xz-utils &&\
    mkdir -p /opt/actions-runner &&\
    tar -xf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -C /opt/actions-runner/ &&\
    chmod +x /opt/start.sh



FROM cruizba/ubuntu-dind:noble-latest AS actions-runner

COPY --from=builder /opt /opt

ENV JAVA_HOME=/usr/lib/jvm/temurin-11-jdk-amd64/

RUN useradd -m -g docker -G sudo docker &&\
    apt-get update -y &&\
    apt-get install -y wget gpg software-properties-common &&\
    wget -O key.gpg https://packages.adoptium.net/artifactory/api/gpg/key/public &&\
    gpg --dearmor -o /usr/share/keyrings/adoptium.gpg key.gpg &&\
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" >/etc/apt/sources.list.d/adoptium.list &&\
    apt-get update -y &&\
    DEBIAN_FRONTEND=noninteractive /opt/actions-runner/bin/installdependencies.sh && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    7zip \
    ant \
    bc \
    build-essential \
    cmake \
    colordiff \
    curl \
    dosfstools \
    doxygen \
    file \
    g++-mingw-w64 \
    g++-multilib \
    gcc \
    gcc-mingw-w64 \
    gcc-multilib \
    git \
    graphviz \
    iproute2 \
    jq \
    kicad \
    lcov \
    librsvg2-bin \
    lsb-release \
    make \
    mtools \
    netbase \
    openjdk-8-jdk-headless \
    openocd \
    openssh-client \
    python3-pip \
    python3-tk \
    ruby-rubygems \
    scour \
    sshpass \
    stlink-tools \
    sudo \
    supervisor \
    temurin-11-jdk \
    time \
    uidmap \
    usbutils \
    valgrind \
    xxd \
    zip \
    && apt-get autoremove -y && apt-get clean -y &&\
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&\
    echo 'APT::Get::Assume-Yes "true";' >/etc/apt/apt.conf.d/90forceyes &&\
    chown -R docker /opt &&\
    update-alternatives --set java /usr/lib/jvm/temurin-11-jdk-amd64/bin/java

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod 644 /etc/supervisor/conf.d/supervisord.conf

WORKDIR /opt

USER docker

VOLUME /opt/actions-runner

ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PATH=/home/docker/.local/bin:$PATH

ENTRYPOINT ["./start.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
