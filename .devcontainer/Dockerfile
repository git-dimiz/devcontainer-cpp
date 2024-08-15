FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

RUN <<EOF
    apt-get -y update
    apt-get -y upgrade
    apt-get -yq install \
        sudo \
        make \
        tio \
        socat \
        sshpass \
        ninja-build \
        ccache \
        parallel \
        git \
        git-lfs \
        build-essential \
        file \
        wget \
        curl \
        jq \
        neovim \
        cmake \
        silversearcher-ag \
        fd-find \
        clang-18 \
        clang-tidy-18 \
        clang-format-18 \
        clangd \
        mold \
        libclang-18-dev \
        gdb-multiarch \
        gcc-14

    apt-get -y clean
    rm -rf /var/lib/apt/lists/*

    update-alternatives --install /usr/bin/run-clang-tidy run-clang-tidy /usr/lib/llvm-18/bin/run-clang-tidy 100
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100

    mkdir -p ~/.ssh
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

    usermod -aG sudo ubuntu
    echo "ubuntu  ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ubuntu
EOF

ARG IWYU_TAG
RUN <<EOF
    git clone -b ${IWYU_TAG} --single-branch --depth 1 https://github.com/include-what-you-use/include-what-you-use /tmp/iwyu
    cmake -S /tmp/iwyu -B /tmp/iwyu/build
    cmake --build /tmp/iwyu/build --parallel
    cmake --install /tmp/iwyu/build
    rm -rf /tmp/iwyu
EOF
