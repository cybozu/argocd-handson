.PHONY: build
build:
	cd book && mdbook build

.PHONY: serve
serve:
	cd book && mdbook serve
