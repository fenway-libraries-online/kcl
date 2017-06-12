include config.mk

build: bin/kcl

install:
	install -d $(PREFIX)/bin $(PREFIX)/libexec
	install bin/kcl $(PREFIX)/bin/
	install bin/kcl-* $(PREFIX)/libexec/

.PHONY: build install
