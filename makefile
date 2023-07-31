.PHONY: default
default: build

.PHONY: install
install: package.json
	@npm install

.PHONY: build
build:
	@./soupault

.PHONE: minify
minify:
	@./scripts/minify.js
	@cp -r dist/images dist/styles minified/

.PHONE: clean
clean:
	@rm -rf dist/ minified/

.PHONY: serve
serve:
	python -m http.server 8008 -d dist

.PHONY: serve-minified
serve-minified:
	python -m http.server 8008 -d minified