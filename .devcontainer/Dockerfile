FROM ubuntu:23.10

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

RUN apt update && \
    apt install -yq \
        make \
        tio \
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
        clang-17 \
        clang-tidy-17 \
        clang-format-17 \
        libclang-17-dev \
        gdb-multiarch \
        gcc-13

RUN update-alternatives --install /usr/bin/run-clang-tidy run-clang-tidy /usr/lib/llvm-17/bin/run-clang-tidy 100
RUN update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-17 100
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-17 100
RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-17 100

RUN mkdir -p ~/.ssh
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

ARG IWYU_TAG
RUN git clone -b ${IWYU_TAG} --single-branch --depth 1 https://github.com/include-what-you-use/include-what-you-use /tmp/iwyu
RUN cmake -S /tmp/iwyu -B /tmp/iwyu/build
RUN cmake --build /tmp/iwyu/build --parallel
RUN cmake --install /tmp/iwyu/build
RUN rm -rf /tmp/iwyu
