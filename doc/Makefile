SOURCES=$(wildcard *.asciidoc)
TARGETS=$(SOURCES:.asciidoc=.html)
SHELL=/bin/bash
RED=\033[0;31m
RESET=\033[0m
GREEN=\033[0;32m

all: doc

doc: ${TARGETS}

%.html: %.asciidoc
	asciidoc $<

clean:
	rm -f *.png *.html

distclean: clean
	rm -f *~

check_prerequisites:
	@echo -n "### Checking asciidoc: ...."
	@path=$$(which asciidoc); if [ -e "$${path}" ]; then echo -e " ($${path}) $(GREEN)fine :)$(RESET)"; else echo -e " $(RED)not found! :($(RESET)"; fi
	@echo -n "### Checking source-highlight: ...."
	@path=$$(which source-highlight); if [ -e "$${path}" ]; then echo -e " ($${path}) $(GREEN)fine :)$(RESET)"; else echo -e " $(RED)not found! :($(RESET)"; fi
	@echo -n "### Checking pygmentize: ...."
	@path=$$(which pygmentize); if [ -e "$${path}" ]; then echo -e " ($${path}) $(GREEN)fine :)$(RESET)"; else echo -e " $(RED)not found! :($(RESET)"; fi
	@echo -n "### Checking ditaa: ...."
	@path=$$(which ditaa); if [ -e "$${path}" ]; then echo -e " ($${path}) $(GREEN)fine :)$(RESET)"; else echo -e " $(RED)not found! :($(RESET)"; fi
	@echo -n "### Checking asciidoc filter 'ditaa-filter': ...."
	@if [[ -e "/etc/asciidoc/filters/ditaa/ditaa-filter.conf" || -e ~/.asciidoc/filters/ditaa/ditaa-filter.conf ]]; then echo -e " ($${path}) $(GREEN)fine :)$(RESET)"; else echo -e " $(RED)not found! :($(RESET)"; fi



.PHONY: all clean check_prerequisites distclean doc
