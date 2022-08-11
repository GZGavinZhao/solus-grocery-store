export CGO_ENABLED = 0
export GOOS = linux
export GOARCH = amd64

.DEFAULT_GOAL = build

.PHONY:
	build

deploy: build
	terraform apply

build:
	go build -o main ./fc/index
	zip indexer.zip main

clean:
	rm main
	rm indexer.zip
