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

VERBOSE ?= 0
LOCAL_BUILD_ENV ?= 0

ifeq ($(VERBOSE),1)
    ECHO :=
else
    ECHO := @
endif

DOCKER_EXE := docker
DOCKER_CONTAINER_NAME := dev-container
DOCKER_CONTAINER_TAG := $(DOCKER_CONTAINER_NAME)
DOCKER_CONTAINER_CID := .devcontainer/$(DOCKER_CONTAINER_NAME).cid
DOCKER_WORKSPACE_DIR := /workspace

STATE_DOCKER_BUILD := .devcontainer/docker-build.state

LOCAL_DIR := $(abspath $(shell pwd))
LOCAL_BUILD_DIR := $(LOCAL_DIR)/build

TYPE ?= Release
ifeq ($(LOCAL_BUILD_ENV),1)
    WORKSPACE_DIR := $(LOCAL_DIR)
else
    WORKSPACE_DIR := $(DOCKER_WORKSPACE_DIR)
endif
BUILD_DIR := $(WORKSPACE_DIR)/build/$(call f_lower,$(TYPE))

CMAKE_OPTS += -S $(WORKSPACE_DIR)
CMAKE_OPTS += -B $(BUILD_DIR)
CMAKE_OPTS += -G Ninja
CMAKE_OPTS += -D CMAKE_BUILD_TYPE=$(TYPE)
CMAKE_OPTS += -D CMAKE_EXPORT_COMPILE_COMMANDS=On
CMAKE_OPTS += -D CMAKE_CXX_COMPILER_LAUNCHER=ccache
CMAKE_OPTS += -D CMAKE_C_COMPILER_LAUNCHER=ccache

ifeq ($(LOCAL_BUILD_ENV),0)
    define f_shell
    $(1)
    endef
else
    define f_shell
    endef
endif

ifeq ($(LOCAL_BUILD_ENV),0)
    define f_exec
    docker exec -it $$(cat $(DOCKER_CONTAINER_CID)) /bin/bash -c "$(1)"
    endef
else
    define f_exec
    /bin/bash -c "$(1)"
    endef
endif

.PHONY: all
all: build

$(STATE_DOCKER_BUILD):
>   $(ECHO)$(call f_shell,$(DOCKER_EXE) build \
       --ssh default=$(shell echo $${SSH_AUTH_SOCK}) \
       --file .devcontainer/Dockerfile \
       --tag $(DOCKER_CONTAINER_TAG) .)
>   $(ECHO)$(call f_shell,touch $(STATE_DOCKER_BUILD))

.PHONY: docker-build
docker-build: $(STATE_DOCKER_BUILD)

.PHONY: docker-rebuild
docker-rebuild:
>   $(ECHO)$(call f_shell,rm $(STATE_DOCKER_BUILD))
>   $(ECHO)make docker-build

$(DOCKER_CONTAINER_CID):
>   $(ECHO)$(call f_shell,$(DOCKER_EXE) run \
        --rm \
        -dt \
        --user $$(id -u):$$(id -g) \
        -e SSH_AUTH_SOCK=/ssh-agent \
        -v $(shell echo $${SSH_AUTH_SOCK}):/ssh-agent \
        --volume=$(LOCAL_DIR):$(DOCKER_WORKSPACE_DIR) \
        --workdir=$(DOCKER_WORKSPACE_DIR) \
        --name $(DOCKER_CONTAINER_NAME) \
        --cidfile $(DOCKER_CONTAINER_CID) \
        $(DOCKER_CONTAINER_TAG))

.PHONY: docker-start
docker-start: docker-build $(DOCKER_CONTAINER_CID)

.PHONY: docker-stop
docker-stop:
>   $(ECHO)[ -f $(DOCKER_CONTAINER_CID) ] && [ "$$(docker container inspect -f '{{.State.Running}}' $$(cat $(DOCKER_CONTAINER_CID)) )" = "true" ] && docker stop $$(cat $(DOCKER_CONTAINER_CID))
>   $(ECHO)rm -f $(DOCKER_CONTAINER_CID)

.PHONY: docker-attach
docker-attach: docker-start
>   $(ECHO)$(call f_shell,$(DOCKER_EXE) exec -it $$(cat $(DOCKER_CONTAINER_CID)) /bin/bash)

.PHONY: attach
attach: docker-attach

.PHONY: setup
setup: docker-stop docker-rebuild

.PHONY: configure
configure: docker-start
>   $(ECHO)$(call f_exec,cmake $(CMAKE_OPTS))

.PHONY: build
build: configure
>   $(ECHO)$(call f_exec,cmake --build $(BUILD_DIR) --target all --parallel)

.PHONY: clean
clean: docker-start
>   $(ECHO)$(call f_exec,cmake --build $(BUILD_DIR) --target clean --parallel)

.PHONY: distclean
distclean: docker-start
>   $(ECHO)$(call f_exec,rm -rf $(BUILD_DIR))

.PHONY: teardown
teardown: distclean docker-stop
>   $(ECHO)$(call f_shell,$(DOCKER_EXE) image rm -f $(DOCKER_CONTAINER_TAG))