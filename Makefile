# This option causes make to display a warning whenever an undefined variable is expanded.
MAKEFLAGS += --warn-undefined-variables

# Disable any builtin pattern rules, then speedup a bit.
MAKEFLAGS += --no-builtin-rules

# If this variable is not set, the program /bin/sh is used as the shell.
SHELL := /bin/bash

# The arguments passed to the shell are taken from the variable .SHELLFLAGS.
#
# The -e flag causes bash with qualifications to exit immediately if a command it executes fails.
# The -u flag causes bash to exit with an error message if a variable is accessed without being defined.
# The -o pipefail option causes bash to exit if any of the commands in a pipeline fail.
# The -c flag is in the default value of .SHELLFLAGS and we must preserve it.
# Because it is how make passes the script to be executed to bash.
.SHELLFLAGS := -eu -o pipefail -c

# Disable any builtin suffix rules, then speedup a bit.
.SUFFIXES:

# Sets the default goal to be used if no targets were specified on the command line.
.DEFAULT_GOAL := help

#
# Variables for the file and directory path
#
SELF_DIR ?= $(subst /Makefile,,$(lastword $(MAKEFILE_LIST)))
ROOT_DIR ?= $(shell $(GIT) rev-parse --show-toplevel)
YAML_FILES ?= $(shell find . -name '*.y*ml')

#
# Variables to be used by Git and GitHub CLI
#
GIT ?= $(shell \command -v git 2>/dev/null)
GH ?= $(shell \command -v gh 2>/dev/null)

#
# Variables to be used by Docker
#
DOCKER ?= $(shell \command -v docker 2>/dev/null)
DOCKER_WORK_DIR ?= /work
DOCKER_RUN_OPTIONS ?=
DOCKER_RUN_OPTIONS += -it
DOCKER_RUN_OPTIONS += --rm
DOCKER_RUN_OPTIONS += -v $(ROOT_DIR):$(DOCKER_WORK_DIR)
DOCKER_RUN_OPTIONS += -w $(DOCKER_WORK_DIR)
DOCKER_RUN_SECURE_OPTIONS ?=
DOCKER_RUN_SECURE_OPTIONS += --user 1111:1111
DOCKER_RUN_SECURE_OPTIONS += --read-only
DOCKER_RUN_SECURE_OPTIONS += --security-opt no-new-privileges
DOCKER_RUN_SECURE_OPTIONS += --cap-drop all
DOCKER_RUN_SECURE_OPTIONS += --network none
DOCKER_RUN ?= $(DOCKER) run $(DOCKER_RUN_OPTIONS)
SECURE_DOCKER_RUN ?= $(DOCKER_RUN) $(DOCKER_RUN_SECURE_OPTIONS)

#
# Variables for the image name
#
PRETTIER ?= $(SECURE_DOCKER_RUN) ghcr.io/tmknom/dockerfiles/prettier:latest
YAMLLINT ?= $(SECURE_DOCKER_RUN) ghcr.io/tmknom/dockerfiles/yamllint:latest
ACTDOCS ?= $(SECURE_DOCKER_RUN) ghcr.io/tmknom/actdocs:latest

#
# CLI configs
#
define yamllint_config
	if [[ -f $(ROOT_DIR)/.yamllint.yml ]]; then echo ".yamllint.yml"; \
	elif [[ -f $(ROOT_DIR)/.yamllint.yaml ]]; then echo ".yamllint.yaml"; \
	else echo "$(SELF_DIR)/.yamllint.yml"; \
	fi
endef
YAMLLINT_CONFIG ?= $(shell $(call yamllint_config))

#
# Lint
#
.PHONY: lint
lint: lint-yaml ## lint

.PHONY: lint-yaml
lint-yaml:
	$(YAMLLINT) --strict --config-file $(YAMLLINT_CONFIG) .
	$(PRETTIER) --check --parser=yaml $(YAML_FILES)

#
# Format code
#
.PHONY: fmt
fmt: fmt-yaml ## format code

.PHONY: fmt-yaml
fmt-yaml:
	$(PRETTIER) --write --parser=yaml $(YAML_FILES)

#
# Document management
#
.PHONY: docs
docs: ## generate docs
	$(ACTDOCS) inject --sort --file=README.md action.yml

#
# Release management
#
.PHONY: release
release: ## release new version
	@select LEBEL in 'patch' 'minor' 'major'; do \
	  case "$${LEBEL}" in \
		'patch') gh workflow run release.yml -f level=patch; break ;; \
		'minor') gh workflow run release.yml -f level=minor; break ;; \
		'major') gh workflow run release.yml -f level=major; break ;; \
		*) echo 'Error: invalid parameter'; exit 1 ;; \
	  esac; \
	done

.PHONY: update-makefile
update-makefile:
	cd $(ROOT_DIR)/$(SELF_DIR) && git pull origin main

.PHONY: help
help: ## show help
	@grep --no-filename -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
