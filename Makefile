# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
GOLANG_VERSION ?= 1.16
GOPATH ?= $(HOME)/go

# set to -V
VERBOSE ?=

export GO111MODULE = on
export GO = go
export PYTHON = python3
export PRECOMMIT = poetry run pre-commit

CWD = $(shell pwd)
BUILD_DIR := CWD

TAG ?= $(eval TAG := $(shell git describe --tags --long --always))$(TAG)
REPO ?= $(shell echo $$(cd ../${BUILD_DIR} && git config --get remote.origin.url) | sed 's/git@\(.*\):\(.*\).git$$/https:\/\/\1\/\2/')
BRANCH ?= $(shell cd ../${BUILD_DIR} && git branch | grep '^*' | awk '{print $$2}')
ARCH = linux

TMPRELEASEDIR = $(shell mktemp -d)
PACKAGE = $(shell echo "same_$(TAG)_$(ARCH)")

all: build

# Run go fmt against code
fmt:
	@${GO} fmt ./cmd/...


# Run go vet against code
vet:
	@${GO} vet ./cmd/...


################################################################################
# Target: build	                                                               #
################################################################################
.PHONY: build
build: build-same

################################################################################
# Target: build-same                                                           #
################################################################################
.PHONY: build-same
build-same: fmt vet
	CGO_ENABLED=0 ARCH=linux GOARCH=amd64 ${GO} build -gcflags '-N -l' -ldflags "-X main.VERSION=$(TAG)" -o bin/$(ARCH)/same main.go
	cp bin/$(ARCH)/same bin/same

# Release tarballs suitable for upload to GitHub release pages
################################################################################
# Target: build-same-tgz                                                       #
################################################################################
.PHONY: build-same-tgz
build-same-tgz: build-same
	@echo $(TMPRELEASEDIR)
	cp bin/$(ARCH)/same $(TMPRELEASEDIR)/same
    # rm -f bin/*.tgz
    # cd $(TMPRELEASEDIR) && tar -cvzf same_$(TAG)_$(ARCH).tar.gz ./same
    # cd cwd
    # rm -rf $(TMPRELEASEDIR)


# push the releases to a GitHub page
################################################################################
# Target: push-to-github-release                                               #
################################################################################
.PHONY: push-to-github-release
push-to-github-release: build-same-tgz
	github-release upload \
	    --user same \
	    --repo same \
	    --tag $(TAG) \
	    --name "same_$(TAG)_$(ARCH).tar.gz" \
	    --file bin/$(ARCH)/same_$(TAG)_$(ARCH).tar.gz

################################################################################
# Target: install                                                              #
################################################################################
.PHONY: install
install: build-same
	@echo copying bin/same to /usr/local/bin
	@cp bin/same /usr/local/bin

#***************************************************************************************************

################################################################################
# Target: clean					                                               #
################################################################################
.PHONY: clean
clean:
	rm -rf test && mkdir test

################################################################################
# Target: test					                                               #
################################################################################
.PHONY: test
test: build-same
	go test ./test/... -v

################################################################################
# Target: lint					                                               #
################################################################################
.PHONY: lint
lint: build-same
	golangci-lint run

