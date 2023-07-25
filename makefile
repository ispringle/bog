.PHONY: default
default: build

.PHONY: install
install: package.json
	@npm install

.PHONY: setup
setup: install
	mkdir -p temp
	@./scripts/css.sh

.PHONY: build
build: install setup
	@./soupault

.PHONE: clean
clean:
	@rm -rf dist/ temp/ site/styles/*

.PHONY: serve
serve:
	python -m http.server 8008 -d dist