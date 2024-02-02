.PHONY: default
default: build

.PHONY: install
install: package.json
	@npm install

.PHONY: build
build:
	@./soupault

.PHONE: clean
clean:
	@rm -rf dist/

.PHONY: serve
serve:
	python -m http.server 8008 -d dist
