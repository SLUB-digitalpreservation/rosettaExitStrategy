REQUIRED_MODULES=$(shell find ./ \( -name "*.p[ml]" -o -name "*.t" \) -exec grep "^use \([A-Za-z][A-Za-z0-9:]\+\)" \{\} \; | sed -e "s/^use \([A-Za-z][A-Za-z0-9:]\+\).*/\1/g" | sort | uniq)
REQUIRED_SYSMODULES=$(shell find ./ \( -name "*.p[ml]" -o -name "*.t" \) -exec grep "^use \([A-Za-z][A-Za-z0-9:]\+\)" \{\} \; | grep -v "SLUB::LZA" | grep "^use [A-Z]" | sed -e "s/^use \([A-Za-z][A-Za-z0-9:]\+\).*/\1/g" | sort | uniq)
PMs=$(shell find ./ -name "*.pm")
PODs=$(PMs:.pm=.pod)

all: perl_tests_ok

clean:
	rm -f perl_tests_ok

distclean: clean
	find ./ -name "*~" | xargs rm -f
	find ./ -name "*.pod" | xargs rm -f
	rm -Rf testdir/
	rm -Rf cover_db/

find_subs:
	find ./ -name "*.pm" -exec grep -E "^\s*sub\s+(\w+)\b" \{\} \;

find_vars:
	find ./ -name '*.pm' -exec grep 'my \$$[A-Za-z0-9_]' \{\} \; | egrep -o '\$$[A-Za-z0-9_]+' | sort | uniq

check_prerequisites:
	@for i in $(REQUIRED_MODULES); do\
	  echo -n "### Checking if Perl-Module '$$i' exists ..." ;\
	  /usr/bin/perl -I./ -e "use Term::ANSIColor; if (eval {require $$i; 1;} ne 1) { print color 'bold red'; print \" not found! :(\n\";} else {print color 'green'; print \"fine! :)\n\";}; print color 'reset';";\
	  done

perl_tests_ok:
	touch perl_tests_ok
	@true

list_required_perl_modules: 
	@for i in $(REQUIRED_SYSMODULES) ; do\
	  echo $$i ;\
	  done

# autpod is part of Pod::Autopod
%.pod:%.pm
	autopod -r $< --pod -w $@ 

doc: $(PODs)

#cover: clean
#	PERL5OPT=-MDevel::Cover $(MAKE) perl_tests_ok
#	cover -ignore_re '.*\.t' -ignore_re '.*prove'
#	@echo report found in cover_db/coverage.html

.PHONY: all clean check_prerequisites doc distclean find_subs list_required_perl_modules perl_tests_ok

