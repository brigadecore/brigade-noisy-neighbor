SHELL ?= /bin/bash

.DEFAULT_GOAL := build

################################################################################
# Version details                                                              #
################################################################################

# This will reliably return the short SHA1 of HEAD or, if the working directory
# is dirty, will return that + "-dirty"
GIT_VERSION = $(shell git describe --always --abbrev=7 --dirty --match=NeVeRmAtCh)

################################################################################
# Containerized development environment-- or lack thereof                      #
################################################################################

ifneq ($(SKIP_DOCKER),true)
	PROJECT_ROOT := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
	GO_DEV_IMAGE := brigadecore/go-tools:v0.1.0

	GO_DOCKER_CMD := docker run \
		-it \
		--rm \
		-e SKIP_DOCKER=true \
		-e GITHUB_TOKEN=$${GITHUB_TOKEN} \
		-e GOCACHE=/workspaces/brigade-noisy-neighbor/.gocache \
		-v $(PROJECT_ROOT):/workspaces/brigade-noisy-neighbor \
		-w /workspaces/brigade-noisy-neighbor \
		$(GO_DEV_IMAGE)

	KANIKO_IMAGE := brigadecore/kaniko:v0.2.0

	KANIKO_DOCKER_CMD := docker run \
		-it \
		--rm \
		-e SKIP_DOCKER=true \
		-e DOCKER_PASSWORD=$${DOCKER_PASSWORD} \
		-v $(PROJECT_ROOT):/workspaces/brigade-noisy-neighbor \
		-w /workspaces/brigade-noisy-neighbor \
		$(KANIKO_IMAGE)

	HELM_IMAGE := brigadecore/helm-tools:v0.1.0

	HELM_DOCKER_CMD := docker run \
	  -it \
		--rm \
		-e SKIP_DOCKER=true \
		-e HELM_PASSWORD=$${HELM_PASSWORD} \
		-v $(PROJECT_ROOT):/workspaces/brigade-noisy-neighbor \
		-w /workspaces/brigade-noisy-neighbor \
		$(HELM_IMAGE)
endif

################################################################################
# Binaries and Docker images we build and publish                              #
################################################################################

ifdef DOCKER_REGISTRY
	DOCKER_REGISTRY := $(DOCKER_REGISTRY)/
endif

ifdef DOCKER_ORG
	DOCKER_ORG := $(DOCKER_ORG)/
endif

DOCKER_IMAGE_NAME := $(DOCKER_REGISTRY)$(DOCKER_ORG)brigade-noisy-neighbor

ifdef HELM_REGISTRY
	HELM_REGISTRY := $(HELM_REGISTRY)/
endif

ifdef HELM_ORG
	HELM_ORG := $(HELM_ORG)/
endif

HELM_CHART_NAME := $(HELM_REGISTRY)$(HELM_ORG)brigade-noisy-neighbor

ifdef VERSION
	MUTABLE_DOCKER_TAG := latest
else
	VERSION            := $(GIT_VERSION)
	MUTABLE_DOCKER_TAG := edge
endif

IMMUTABLE_DOCKER_TAG := $(VERSION)

################################################################################
# Tests                                                                        #
################################################################################

.PHONY: lint
lint:
	$(GO_DOCKER_CMD) sh -c ' \
		golangci-lint run --config golangci.yaml \
	'

.PHONY: test-unit
test-unit:
	$(GO_DOCKER_CMD) sh -c ' \
		go test \
			-v \
			-timeout=60s \
			-race \
			-coverprofile=coverage.txt \
			-covermode=atomic \
			./... \
	'

.PHONY: lint-chart
lint-chart:
	$(HELM_DOCKER_CMD) sh -c ' \
		cd charts/brigade-noisy-neighbor && \
		helm dep up && \
		helm lint . \
	'

################################################################################
# Build                                                                        #
################################################################################

.PHONY: build
build:
	$(KANIKO_DOCKER_CMD) kaniko \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(GIT_VERSION) \
		--dockerfile /workspaces/brigade-noisy-neighbor/Dockerfile \
		--context dir:///workspaces/brigade-noisy-neighbor/ \
		--no-push

################################################################################
# Publish                                                                      #
################################################################################

.PHONY: publish
publish: push publish-chart

.PHONY: push
push:
	$(KANIKO_DOCKER_CMD) sh -c ' \
		docker login $(DOCKER_REGISTRY) -u $(DOCKER_USERNAME) -p $${DOCKER_PASSWORD} && \
		kaniko \
			--build-arg VERSION="$(VERSION)" \
			--build-arg COMMIT="$(GIT_VERSION)" \
			--dockerfile /workspaces/brigade-noisy-neighbor/Dockerfile \
			--context dir:///workspaces/brigade-noisy-neighbor/ \
			--destination $(DOCKER_IMAGE_NAME):$(IMMUTABLE_DOCKER_TAG) \
			--destination $(DOCKER_IMAGE_NAME):$(MUTABLE_DOCKER_TAG) \
	'

.PHONY: publish-chart
publish-chart:
	$(HELM_DOCKER_CMD) sh	-c ' \
		helm registry login $(HELM_REGISTRY) -u $(HELM_USERNAME) -p $${HELM_PASSWORD} && \
		cd charts/brigade-noisy-neighbor && \
		helm dep up && \
		sed -i "s/^version:.*/version: $(VERSION)/" Chart.yaml && \
		sed -i "s/^appVersion:.*/appVersion: $(VERSION)/" Chart.yaml && \
		helm chart save . $(HELM_CHART_NAME):$(VERSION) && \
		helm chart push $(HELM_CHART_NAME):$(VERSION) \
	'

################################################################################
# Targets to facilitate hacking on Brigade Noisy Neighbor.                     #
################################################################################

.PHONY: hack-build
hack-build:
	docker build \
		-f Dockerfile \
		-t $(DOCKER_IMAGE_NAME):$(VERSION) \
		--build-arg VERSION='$(VERSION)' \
		--build-arg COMMIT='$(GIT_VERSION)' \
		.

.PHONY: hack-push
hack-push: hack-build
	docker push $(DOCKER_IMAGE_NAME):$(IMMUTABLE_DOCKER_TAG)

IMAGE_PULL_POLICY ?= Always

.PHONY: hack-deploy
hack-deploy:
	helm dep up charts/brigade-noisy-neighbor && \
	helm upgrade brigade-noisy-neighbor charts/brigade-noisy-neighbor \
		--install \
		--create-namespace \
		--namespace brigade-noisy-neighbor \
		--wait \
		--timeout 60s \
		--set image.repository=$(DOCKER_IMAGE_NAME) \
		--set image.tag=$(IMMUTABLE_DOCKER_TAG) \
		--set image.pullPolicy=$(IMAGE_PULL_POLICY)

.PHONY: hack
hack: hack-push hack-deploy

# Convenience target for loading image into a KinD cluster
.PHONY: hack-load-image
hack-load-image:
	@echo "Loading $(DOCKER_IMAGE_NAME):$(IMMUTABLE_DOCKER_TAG)"
	@kind load docker-image $(DOCKER_IMAGE_NAME):$(IMMUTABLE_DOCKER_TAG) \
			|| echo >&2 "kind not installed or error loading image: $(DOCKER_IMAGE_NAME):$(IMMUTABLE_DOCKER_TAG)"
