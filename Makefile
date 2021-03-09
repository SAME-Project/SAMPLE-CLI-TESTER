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

TAG ?= $(eval TAG := $(shell git describe --tags --always))$(TAG)
REPO ?= $(shell echo $$(cd ../${BUILD_DIR} && git config --get remote.origin.url) | sed 's/git@\(.*\):\(.*\).git$$/https:\/\/\1\/\2/')
BRANCH ?= $(shell cd ../${BUILD_DIR} && git branch | grep '^*' | awk '{print $$2}')
ARCH = linux

RELEASE_USER := SAME-Project
RELEASE_REPO :=SAMPLE-CLI-TESTER

TMPRELEASEWORKINGDIR := $(shell mktemp -d -t same-release-dir.XXXXXXX)
TMPARTIFACTDIR := $(shell mktemp -d -t same-artifact-dir.XXXXXXX)
PACKAGE := $(shell echo "same_$(TAG)_$(ARCH)")

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
	@echo "CWD: $(shell pwd)"
	@echo "RELEASE DIR: $(TMPRELEASEWORKINGDIR)"
	@echo "ARTIFACT DIR: $(TMPARTIFACTDIR)"
	mkdir $(TMPARTIFACTDIR)/$(PACKAGE)
	cp bin/$(ARCH)/same $(TMPARTIFACTDIR)/$(PACKAGE)/same
	cd $(TMPRELEASEWORKINGDIR)
	openssl dgst -sha256 -sign private.pem -passin pass:$(PRIVATE_KEY_PASSPHRASE) -out $(TMPRELEASEWORKINGDIR)/sign.sha256 $(TMPARTIFACTDIR)/$(PACKAGE)/same
	openssl base64 -in $(TMPRELEASEWORKINGDIR)/sign.sha256 -out $(TMPARTIFACTDIR)/$(PACKAGE)/same.signature.sha256
	@echo "tar cvzf $(TMPARTIFACTDIR)/$(PACKAGE).tar.gz -C $(TMPARTIFACTDIR)/$(PACKAGE) $(PACKAGE)"
	tar cvzf $(TMPARTIFACTDIR)/$(PACKAGE).tar.gz -C $(TMPARTIFACTDIR)/$(PACKAGE) .
	openssl dgst -sha256 -sign private.pem -passin pass:$(PRIVATE_KEY_PASSPHRASE) -out $(TMPRELEASEWORKINGDIR)/tarsign.sha256 $(TMPARTIFACTDIR)/$(PACKAGE).tar.gz
	openssl base64 -in $(TMPRELEASEWORKINGDIR)/tarsign.sha256 -out $(TMPARTIFACTDIR)/$(PACKAGE).tar.gz.signature.sha256
	@echo "BINARY_TARBALL=$(TMPARTIFACTDIR)/$(PACKAGE).tar.gz" >> $(GITHUB_ENV)
	@echo "BINARY_TARBALL_NAME=$(PACKAGE).tar.gz" >> $(GITHUB_ENV)
	@echo "BINARY_TARBALL_SIGNATURE=$(TMPARTIFACTDIR)/$(PACKAGE).tar.gz.signature.sha256" >> $(GITHUB_ENV)
	@echo "BINARY_TARBALL_SIGNATURE_NAME=$(PACKAGE).tar.gz.signature.sha256" >> $(GITHUB_ENV)

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

