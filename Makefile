include config.mk

build: bin/kcl

install:
	install -d $(PREFIX)/bin $(PREFIX)/libexec
	install bin/kcl $(PREFIX)/bin/
	install libexec/kcl-* $(PREFIX)/libexec/

.PHONY: build install
