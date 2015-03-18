rosettaExitStrategy
===================

This script processes a '/permanent'-directory of an ExLibris Rosetta digital
longterm archive system and parses the metadata in AIP-packages and builds a
database to find AIPs and associated metadata independently from the Exlibris
Rosetta system.

The script scans a given repository and creates an SQL script to create a
database.

This is part of the exit-strategy, for details, see asciidoc file
'doc/exit_strategie.asciidoc' (also contains ER-diagram for database)

file was tested with postgres-database sucessfully

using:
[source,bash]
--------------------------------------------------------
$> psql -U romeyke -d exit_strategy \
   -f rosetta_exit_strategy/tmp.sql -L rosetta_exit.log
--------------------------------------------------------

