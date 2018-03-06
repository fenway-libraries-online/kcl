include config.mk

build: bin/kcl

install:
	install -d $(PREFIX)/bin $(PREFIX)/libexec $(PREFIX)/libexec/kcl
	install bin/kcl $(PREFIX)/bin/
	install libexec/*.pl $(PREFIX)/libexec/kcl

.PHONY: build install
