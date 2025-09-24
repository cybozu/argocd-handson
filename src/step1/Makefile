SOURCES = $(wildcard *.go) go.mod
CONTAINER_REPOSITORY = docker.example.com/hello-server

hello-server: $(SOURCES)
	 CGO_ENABLED=0 go build -trimpath -o $@

.PHONY: image
image: hello-server
	docker build -t $(CONTAINER_REPOSITORY):latest .

.PHONY: push
push: image
	docker tag $(CONTAINER_REPOSITORY):latest $(CONTAINER_REPOSITORY):$(shell git rev-parse HEAD)
	# 通常ではここで `docker push` を行うが、このチュートリアルでは代わりに `kind load` を使う。
	kind load docker-image $(CONTAINER_REPOSITORY):latest
	kind load docker-image $(CONTAINER_REPOSITORY):$(shell git rev-parse HEAD)

.PHONY: clean
clean:
	rm -f hello-server
