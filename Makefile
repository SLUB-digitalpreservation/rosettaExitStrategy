###############################################################################
###                                                                         ###
### all:                  compiles all stuff                                ###
### clean:                cleans all stuff                                  ###
### check_prerequisites   checks if all prerequisites to compile are fine   ###
### distclean:            makes Mr Proper clean                             ###
### build:                generates a builded environment,                  ###
###                       defaults in ./build/                              ###
### buildclean:           removes builded environment                       ###
### force_build:          force build also if perl tests failed             ###
### install:              installs builded environment on system            ###
### uninstall:            removes strong related stuff from system if part  ###
###                       of previously builded environment                 ###
###############################################################################

# If you unsure, the following steps will be a good idea in general:
# $> make check_prerequisites
# $> make clean; build; install





PROGRAM=rosettaExitStrategy
PREFIX?=/usr/local/
PATH_PERL_MOD=perl/
PATH_SHARE=share/${PROGRAM}/
PATH_DOC=${PATH_SHARE}/doc/
PATH_XSL=${PATH_SHARE}/xsl/
PATH_XSD=${PATH_SHARE}/schema/
PATH_BIN=bin/
BUILD?=./build/
SHELL=/bin/bash

include ../subprojects.mk

.PHONY: all clean check_prerequisites distclean doc test uninstall 
