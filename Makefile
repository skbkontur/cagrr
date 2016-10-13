VERSION := $(shell git describe --always --tags --abbrev=0 | tail -c +2)
RELEASE := $(shell git describe --always --tags | awk -F- '{ if ($$2) dot="."} END { printf "1%s%s%s%s\n",dot,$$2,dot,$$3}')
VENDOR := "SKB Kontur"
URL := "https://github.com/skbkontur/cagrr"
LICENSE := "BSD"

default: clean prepare test build packages

prepare:
		go get github.com/kardianos/govendor
		govendor sync

clean:
	@rm -rf build

test:
	@go test -cover -tags="cagrr" -v ./...

build:
	mkdir build
	cd cmd/cagrr && go build -ldflags "-X main.version=$(VERSION)-$(RELEASE)" -o ../../build/root/usr/bin/cagrr

run:
	go run cmd/cagrr/main.go -v debug

tar:
	mkdir -p build/root/usr/local/bin
	mv build/cagrr build/root/usr/local/bin/
	tar -czvPf build/cagrr-$(VERSION)-$(RELEASE).tar.gz -C build/root  .

rpm:
	fpm -t rpm \
		-s "tar" \
		--description "Cassandra Go Range Repair" \
		--vendor $(VENDOR) \
		--url $(URL) \
		--license $(LICENSE) \
		--name "cagrr" \
		--version "$(VERSION)" \
		--iteration "$(RELEASE)" \
		-p build \
		build/cagrr-$(VERSION)-$(RELEASE).tar.gz

deb:
	fpm -t deb \
		-s "tar" \
		--description "Cassandra Go Range Repair" \
		--vendor $(VENDOR) \
		--url $(URL) \
		--license $(LICENSE) \
		--name "cagrr" \
		--version "$(VERSION)" \
		--iteration "$(RELEASE)" \
		-p build \
		build/cagrr-$(VERSION)-$(RELEASE).tar.gz

packages: clean build tar rpm deb
