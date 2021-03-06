VERSION := $(shell git describe --always --tags --abbrev=0 | tail -c +2)
RELEASE := $(shell git describe --always --tags | awk -F- '{ if ($$2) dot="."} END { printf "1%s%s%s%s\n",dot,$$2,dot,$$3}')
VENDOR := "SKB Kontur"
LICENSE := "BSD"
URL := "https://github.com/skbkontur/cagrr"

default: clean prepare test build packages

prepare:
	sudo apt-get -qq update
	sudo apt-get install -y rpm ruby-dev gcc make
	gem install fpm
	go get -v github.com/modocache/gover
	go get -v golang.org/x/tools/cmd/cover
	go get -v github.com/mattn/goveralls
	go get -v github.com/onsi/ginkgo/ginkgo
	go get -v github.com/onsi/gomega
	go get -v github.com/onsi/gomega/gstruct
	go get github.com/kardianos/govendor
	govendor sync

clean:
	@rm -rf build

test:
	ginkgo -r -randomizeAllSpecs -progress -cover -coverpkg=./... -trace -race

integration:
	@go test -cover -tags="integration" -v ./...

build:
	mkdir build
	go build -ldflags "-X main.version=$(VERSION)-$(RELEASE)" -o build/cagrr

run:
	go run main.go -v debug

up: clean prepare build run

tar:
	mkdir -p build/root/usr/local/bin
	mkdir -p build/root/usr/lib/systemd/system
	mkdir -p build/root/etc/cagrr

	mv build/cagrr build/root/usr/local/bin/cagrr
	cp pkg/cagrr.service build/root/usr/lib/systemd/system/cagrr.service
	cp pkg/config.yml build/root/etc/cagrr/config.yml

	tar -czvPf build/cagrr-$(VERSION)-$(RELEASE).tar.gz -C build/root  .

rpm:
	fpm -t rpm \
		-s "tar" \
		--description "Cassandra Go Range Repair Scheduler" \
		--vendor $(VENDOR) \
		--url $(URL) \
		--license $(LICENSE) \
		--name "cagrr" \
		--version "$(VERSION)" \
		--iteration "$(RELEASE)" \
		--after-install "./pkg/postinst" \
		--config-files "/etc/cagrr/config.yml" \
		-p build \
		build/cagrr-$(VERSION)-$(RELEASE).tar.gz

deb:
	fpm -t deb \
		-s "tar" \
		--description "Cassandra Go Range Repair Scheduler" \
		--vendor $(VENDOR) \
		--url $(URL) \
		--license $(LICENSE) \
		--name "cagrr" \
		--version "$(VERSION)" \
		--iteration "$(RELEASE)" \
		--after-install "./pkg/postinst" \
		-p build \
		build/cagrr-$(VERSION)-$(RELEASE).tar.gz

packages: clean build tar rpm deb
