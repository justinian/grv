GRV_VERSION=$(shell git describe --long --tags --dirty --always --match=v*.*.* 2>/dev/null || echo 'Unknown')
GRV_BUILD_DATETIME=$(shell date '+%Y-%m-%d %H:%M:%S %Z')

GOCMD=go
GOLINT=golint

BINARY?=grv
GRV_SOURCE_DIR=./cmd/grv
GRV_LDFLAGS=-X 'main.version=$(GRV_VERSION)' -X 'main.buildDateTime=$(GRV_BUILD_DATETIME)'
GRV_STATIC_LDFLAGS=-extldflags '-lncurses -ltinfo -lgpm -static'
GRV_BUILD_FLAGS=-ldflags "$(GRV_LDFLAGS)"
GRV_STATIC_BUILD_FLAGS=-ldflags "$(GRV_LDFLAGS) $(GRV_STATIC_LDFLAGS)"

GOPATH_DIR:=$(shell go env GOPATH)
GOBIN_DIR:=$(GOPATH_DIR)/bin

all: $(BINARY)

$(BINARY):
	$(GOCMD) build $(GRV_BUILD_FLAGS) -o $(BINARY) $(GRV_SOURCE_DIR)

.PHONY: install
install: $(BINARY)
	install -m755 -d $(GOBIN_DIR)
	install -m755 $(BINARY) $(GOBIN_DIR)

.PHONY: update-test
update-test:
	$(GOCMD) get golang.org/x/lint/golint
	$(GOCMD) get github.com/stretchr/testify/mock
	$(GOCMD) get github.com/stretchr/testify/assert

# Only tested on Ubuntu.
# Requires dependencies static library versions to be present alongside dynamic ones
$(BINARY)-static:
	$(GOCMD) build $(GRV_STATIC_BUILD_FLAGS) -o $(BINARY)-static $(GRV_SOURCE_DIR)

.PHONY: test
test: $(BINARY) doc update-test
	$(GOCMD) test $(GRV_BUILD_FLAGS) $(GRV_SOURCE_DIR)
	# $(GOCMD) vet $(GRV_SOURCE_DIR)
	$(GOLINT) -set_exit_status $(GRV_SOURCE_DIR)

.PHONY: doc
doc: $(BINARY)
	@GRV_GENERATE_DOCUMENTATION=1 ./$(BINARY)

.PHONY: update-latest-github-release
update-latest-github-release:
	$(GOCMD) get github.com/google/go-github/github
	$(GOCMD) get golang.org/x/oauth2
	$(GOCMD) run util/update_latest_release.go

.PHONY: clean
clean:
	rm -f $(BINARY)
