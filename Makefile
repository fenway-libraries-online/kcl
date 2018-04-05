include config.mk

build: bin/kcl bin/kosh

install: check
	install -d $(PREFIX)/bin $(PREFIX)/libexec $(PREFIX)/libexec/kcl
	install bin/* $(PREFIX)/bin/
	install libexec/*.pl $(PREFIX)/libexec/kcl

check:
	./check-syntax

.PHONY: build check install
