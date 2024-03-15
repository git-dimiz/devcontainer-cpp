SHELL := bash
.ONESHELL:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >
.DEFAULT_GOAL = all
.SHELLFLAGS := -e -o pipefail -c

define f_lower
$$(echo "$(1)" | tr '[:upper:]' '[:lower:]')
endef

DEVCONTAINER_ENV ?= 0
TYPE ?= Release
PLATFORM ?= x64-clang
BUILD_DIR := build/$(call f_lower,$(PLATFORM))/$(call f_lower,$(TYPE))
DEVCONTAINER_DIR := .devcontainer
DOCKER_CONTAINER_NAME := cpp
DOCKER_COMPOSE_YML := $(DEVCONTAINER_DIR)/docker-compose.yml

CMAKE_OPTS += -S .
CMAKE_OPTS += -B $(BUILD_DIR)
CMAKE_OPTS += -G Ninja
CMAKE_OPTS += -D CMAKE_BUILD_TYPE=$(TYPE)
CMAKE_OPTS += -D CMAKE_EXPORT_COMPILE_COMMANDS=On
CMAKE_OPTS += -D CMAKE_CXX_COMPILER_LAUNCHER=ccache
CMAKE_OPTS += -D CMAKE_C_COMPILER_LAUNCHER=ccache
ifeq ($(PLATFORM),x64-gcc)
    CMAKE_PREFIX_OPTS := CC=gcc CXX=g++
else ifeq ($(PLATFORM),x64-clang)
    CMAKE_PREFIX_OPTS := CC=clang CXX=clang++
endif

ifeq ($(DEVCONTAINER_ENV),0)
    define f_shell
    $(1)
    endef
else
    define f_shell
    endef
endif

ifeq ($(DEVCONTAINER_ENV),0)
    define f_exec
    docker exec -it $(DOCKER_CONTAINER_NAME) /bin/bash -c "$(1)"
    endef
else
    define f_exec
    /bin/bash -c "$(1)"
    endef
endif

.PHONY: all
all: build

.PHONY: docker-compose-up
docker-compose-up:
>   $(call f_shell,docker compose -f $(DOCKER_COMPOSE_YML) up -d)

.PHONY: docker-compose-down
docker-compose-down:
>   $(call f_shell,docker rm $(DOCKER_CONTAINER_NAME) || true)
>   $(call f_shell,docker compose -f $(DOCKER_COMPOSE_YML) down $(DOCKER_CONTAINER_NAME) || true)

.PHONY: docker-attach
docker-attach: docker-compose-up
>   $(call f_shell,docker exec -it $(DOCKER_CONTAINER_NAME) /bin/bash)

.PHONY: attach
attach: docker-attach

.PHONY: setup
setup: docker-compose-down docker-compose-up

.PHONY: configure
configure: docker-compose-up
>   $(call f_exec,$(CMAKE_PREFIX_OPTS) cmake $(CMAKE_OPTS))

.PHONY: build
build: configure
>   $(call f_exec,cmake --build $(BUILD_DIR) --target all --parallel)

.PHONY: clean
clean: docker-compose-up
>   $(call f_exec,cmake --build $(BUILD_DIR) --target clean --parallel)

.PHONY: distclean
distclean: docker-compose-up
>   $(call f_exec,rm -rf $(BUILD_DIR))

.PHONY: teardown
teardown: distclean docker-compose-down
