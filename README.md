## Goal

The goal of this project is to use Visual Studio Code in a development container environment for C++ development. We utilize a Makefile as a simple wrapper to enable running the project both in a Docker container environment as well as locally.

## Requirements

- GNU Make
- Bash
- Docker
- Docker Compose

### Optional

- Visual Studio Code with the following extensions:
  - Remote Containers (ID: `ms-vscode-remote.remote-containers`)

## Setup with Visual Studio Code

Before starting Visual Studio Code in the development container environment, it is important to ensure that the container is not running. To guarantee this, run `make down` before switching.

## Manual Setup

To set up the project, run the following command:

```bash
make setup
```

## Build Project

You can build the project using the following commands:

```bash
# Run the default build target
make

# Build with Clang and release configuration
PLATFORM=x64-clang TYPE=Release make

# Build with GCC and debug configuration
PLATFORM=x64-gcc TYPE=Debug make

# Build using the local toolchain (no Docker required, but container tools need to be installed locally)
DEVCONTAINER_ENV=0 make
```

These commands provide flexibility to build the project with different configurations, compilers, and environments. Adjust the parameters according to your specific requirements.