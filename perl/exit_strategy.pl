#!/usr/bin/perl -w
###############################################################################
# Author: Andreas Romeyke
# SLUB Dresden, Department Longterm Preservation
#
# scans a given repository and creates an SQL script to create a database. 
# This is part of the exit-strategy for details, see asciidoc file
# exit_strategie.asciidoc (also contains ER-diagram for database)
#
# file tested with postgres-database
#
# using:  
#         psql -U romeyke -d exit_strategy \
#              -f rosetta_exit_strategy/tmp.sql -L rosetta_exit.log
#
###############################################################################

use 5.14.0;
use strict;
use warnings;
use Carp;
use File::Basename;
use File::Find;
use XML::XPath;
use XML::XPath::XMLParser;

# guarantee, that output will be UTF8
binmode(STDOUT, ":encoding(UTF-8)");
my $db_name="exit_strategy";
my $schema_name="exit_strategy";
my $sourcetype="hdd"; #default value

###############################################################################
# write database creation
# write tables creation
# scan repository
#   if IE.xml file found, read its metadata, create SQL add entry
#   write SQL add entry
###############################################################################
sub write_database_creation {
     # non standard conform SQL keywords
     #say "CREATE DATABASE $db_name;";
     #say "CREATE SCHEMA $schema_name;";
     #say "USE ";
}

# write tables creation;:
sub write_tables_creation {
  # Transactions for tables creation
  say "BEGIN;";

  # SEQUENCE
  say "/* create SEQUENCE generator */";
  say "CREATE SEQUENCE serial START 1;";

  # AIP
  say "/* create AIP table */";
  say "CREATE TABLE aip (";
  say "\tid INT PRIMARY KEY DEFAULT nextval('serial'),";
  say "\tie_id VARCHAR(30) NOT NULL UNIQUE";
  say ");";
  # IEFILE
  say "/* create IEFILE table */";
  say "CREATE TABLE metadatafile (";
  say "\tid INT PRIMARY KEY DEFAULT nextval('serial'),";
  say "\taip_id INT NOT NULL REFERENCES aip (id),";
  say "\tlocation VARCHAR(1024) NOT NULL,";
  say "\tsourcetype VARCHAR(30) NOT NULL";
  say ");";
  # DC
  say "/* create DC table */";
  say "CREATE TABLE dc (";
  say "\tid INT PRIMARY KEY DEFAULT nextval('serial'),";
  say "\taip_id INT NOT NULL REFERENCES aip (id),";
  say "\telement VARCHAR(30) NOT NULL,";
  say "\tvalue VARCHAR(1024) NOT NULL";
  say ");";
  # FILE
  say "/* create FILE table */";      
  say "CREATE TABLE sourcedatafile (";
  say "\tid INT PRIMARY KEY DEFAULT nextval('serial'), ";
  say "\taip_id INT NOT NULL REFERENCES aip (id),";
  say "\tname VARCHAR(1024) NOT NULL";
  say ");";
  # LOCAT
  say "/* create LOCAT table */";            
  say "CREATE TABLE sourcedatalocat (";
  say "\tid INT PRIMARY KEY DEFAULT nextval('serial'),";
  say "\tfile_id INT NOT NULL REFERENCES sourcedatafile (id),";
  say "\tlocation VARCHAR(1024) NOT NULL,";
  say "\tsourcetype VARCHAR(30) NOT NULL";
  say ");";
  #end transaction
  say "COMMIT;";
  return;
}

###############################################################################
# Prepare SQL INSERT Statements for AIPs
###############################################################################
sub write_prepare_insert {
  say "BEGIN;";
  say "PREPARE aip_plan (varchar) AS";
  say "  INSERT INTO aip (ie_id) VALUES (\$1);";
  say "PREPARE ie_plan (varchar, varchar, varchar) AS";
  say "  INSERT INTO metadatafile (aip_id, location, sourcetype) VALUES (";
  say "    (SELECT id FROM aip WHERE aip.ie_id=\$1), \$2, \$3";
  say "  );";
  say "PREPARE file_plan (varchar, varchar) AS";
  say "  INSERT INTO sourcedatafile (aip_id, name) VALUES (";
  say "    (SELECT id FROM aip WHERE aip.ie_id=\$1), \$2";
  say "  );";
  say "PREPARE locat_plan (varchar, varchar, varchar, varchar) AS";
  say "  INSERT INTO sourcedatalocat (file_id, location, sourcetype) VALUES (";
  say "    (SELECT sourcedatafile.id FROM sourcedatafile,aip WHERE";
  say "    sourcedatafile.aip_id=aip.id AND aip.ie_id=\$1 AND";
  say "    sourcedatafile.name=\$2), \$3, \$4";
  say "  );";
  say "PREPARE dc_plan (varchar, varchar, varchar) AS";
  say "  INSERT INTO dc (aip_id, element, value) VALUES (";
  say "    (SELECT id FROM aip WHERE aip.ie_id=\$1), \$2, \$3";
  say "  );";
  say "COMMIT;";
  return;
}


###############################################################################
# write add SQL entry, expects a hashref which contains ff. params 
# (foreach file location/copy):
# INSERT INTO aip (ie_id) VALUES ($ieid);
# INSERT INTO iefile (aip_id, location, sourcetype) VALUES (
#       (SELECT id FROM aip where aip.ieid = $ieid), $location, $sourcetype);
# INSERT INTO file (aip_id, name) VALUES (
#       (SELECT id FROM aip where aip.ieid = $ieid), $name);
# INSERT INTO locat (file_id, location, sourcetype) VALUES (
#       (SELECT file.aip_id FROM file where file.aip_id = aip.id 
#        AND aip.ie_id=$ieid), $location, $sourcetype)
# INSERT INTO dc (aip_id, element, value) VALUES (
#       (SELECT id FROM aip where aip.ieid = $ieid), $element, $value);
# TODO: needs additional work
# expects a reference of an hash:
#    $ret{"filename" } = $filename;
#     $ret{"title"} = $title;
#     $ret{"repid"} = $repid;
#     $ret{"files"} = \@files;
#     $ret{"dcrecords"} = \@dcrecords;
###############################################################################
sub write_addsql {
  my $refhash = $_[0];
  my $ieid = basename($refhash->{"filename"},qw/.xml/);
  say "BEGIN;";
  say "EXECUTE aip_plan ('$ieid');";
  # FIXME if multiple locations exists
  my $iefile = basename($refhash->{"filename"});
  say "EXECUTE ie_plan ('$ieid', '$iefile', '$sourcetype');";
  foreach my $location (@{$refhash->{"files"}}) {
    my $file = basename($location); # FIXME if multiple locations 
    my $dir = dirname($location);
    say "EXECUTE file_plan ('$ieid', '$file');";
    say "EXECUTE locat_plan ('$ieid', '$file', '$location', '$sourcetype' );";
  }
  foreach my $dcpair   (@{$refhash->{"dcrecords"}}) {
    my ($dckey,$dcvalue) = @{$dcpair};
    # quote ' in dcvalue
    $dcvalue=~tr/'/"/;
    say "EXECUTE dc_plan ( '$ieid', '$dckey', '$dcvalue');";
  }
  say "COMMIT;";
  say "\n"; 
  return;
}



###############################################################################
# add INDEX and other TRICKs to increase performance
###############################################################################
sub write_index_creation() {
  say "-- BEGIN;";
  say "-- CREATE UNIQUE INDEX aip_index on aip (ie_id);";
  say "-- COMMIT;";
  return;
}

###############################################################################
# checks if a given string from from a given file contains only utf-8 chars
# which are compatible to common used databases
###############################################################################
sub check_if_db_conform ($$) {
  my $string = "$_[0]";
  my $filename = $_[1];
  if ($string ne '') {
    if ( not utf8::is_utf8($string)) { 
      croak "no utf8: '$string' in file '$filename'\n"; 
    }
  }#
  return;
}


###############################################################################
#
# /mets:mets/mets:dmdSec[1]/mets:mdWrap[1]/mets:xmlData[1]/dc:record[1]/dc:title[1]
# /mets:mets/mets:amdSec[1]/mets:techMD[1]/mets:mdWrap[1]/mets:xmlData[1]/dnx[1]/section[1]/record[1]/key[2] 
# mit ID=Label und Wert = LOCAL
# dort die ID von techMD (Referenz für Files)
#
# Files via /mets:mets/mets:fileSec[1]/mets:fileGrp[1]/mets:file[1]/mets:FLocat[1]
#
###############################################################################
sub parse_iexml {
  my $filename = $_[0];
    # create object
  my $xp = XML::XPath->new (filename => $filename);
  ############################################
  # get title
  my $title = $xp->findvalue('/mets:mets/mets:dmdSec/mets:mdWrap[1]/mets:xmlData[1]/dc:record/dc:title[1]');
  check_if_db_conform($title, $filename);
  ############################################
  # get dc-records
  my @dcrecords;
  my $dcnodes = $xp->find('/mets:mets/mets:dmdSec/mets:mdWrap/mets:xmlData/dc:record/*');
  foreach my $dcnode ($dcnodes->get_nodelist) {
    my $key = $dcnode->getName(".");
    my $value = $dcnode->findvalue(".");
    if (defined $value) {
      $value=~s/\n/ /g;
      $value=~s/'/\\'/g;
    }
    check_if_db_conform ($value, $filename);
    my @pair;
    push @pair, $key;
    push @pair, $value;
    push @dcrecords, \@pair;
  }
  ############################################
  # get right representation ID (has a dnx-section with <key id=label>LOCAL</key>)
  my $repids = $xp->find('/mets:mets/mets:amdSec');
  my $repid;
  # FIXME: if only one represenation exists (Qucosa), select this. If there
  # are more than one, use them with label LOCAL
  my @repnodes = $repids->get_nodelist;

  $repid = $repnodes[0]->findvalue('@ID' );
  foreach my $node (@repnodes) {
    my $id = $node->findvalue('@ID' );
    check_if_db_conform($id, $filename);
    #/mets:mets/mets:amdSec[1]/mets:techMD[1]/mets:mdWrap[1]/mets:xmlData[1]/dnx[1]/section[1]/record[1]/key[1]
    #
    if ($node->findvalue('mets:techMD/mets:mdWrap/mets:xmlData/dnx/section/record/key[@id=\'label\']') eq 'LOCAL') {                   
      $repid=$id;
    }
    #print XML::XPath::XMLParser::as_string($node), "\n\n"; 
  }
  ############################################
  # get all files of LOCAL representation
  my @files;
  my $filegrpnodes = $xp->find('/mets:mets/mets:fileSec/mets:fileGrp');
  foreach my $filegrpnode ($filegrpnodes->get_nodelist) {
    #die XML::XPath::XMLParser::as_string($filegrpnode), "\n\n";
    #die Dumper($filegrpnode);
    if ($filegrpnode->findvalue('@ADMID') eq $repid) {
      #die Dumper($filegrpnode);
      my $filesnodes = $filegrpnode ->find("mets:file/mets:FLocat");
      foreach my $filesnode ($filesnodes->get_nodelist) {
        my $value = $filesnode->findvalue('@xlin:href');
        check_if_db_conform($value, $filename);
        push @files,  sprintf("%s", $value);
      }
    }
  }
  my %ret;
  $ret{"filename" } = $filename;
  $ret{"title"} = $title;
  $ret{"repid"} = $repid;
  $ret{"files"} = \@files;
  $ret{"dcrecords"} = \@dcrecords;
  return \%ret;
}

###############################################################################
# because ExLibris Rosetta produces filenames of following format:
# V\d+-IE\d+\.xml
# e.G.: 
# V1-IE23891.xml
# V1-IE94621.xml
# V2-IE23891.xml
# …
# we must find the relevant file with highest V-value, in example the file
# "V2-IE23891.xml"
#
# this function gets an array reference with all possible files of given regEx
# and returns an array reference with reduced files using only highest V-value
################################################################################
sub find_newest_iefile_version ($) {
  my $files = $_[0];
  #say "$files=";
  #say Dumper($files);
  my %fileshash;
  foreach my $file (@{ $files } ) {
    $file=~m/^(.+?V)(\d+)(-IE\d+\.xml)$/;
    my ($prefix, $version, $suffix) = ($1, $2, $3);
    if (defined $fileshash{$suffix}) {
      my ($stored_version, $stored_prefix) = @{ $fileshash{$suffix} };
      if ($version > $stored_version) {
        carp "replaced $stored_version with $version of $suffix";
        my @tmp = ($version, $prefix);
        $fileshash{$suffix} = \@tmp;
      }
    } else {
        my @tmp = ($version, $prefix);
        $fileshash{$suffix} = \@tmp;
    }
  }
  # build new array
  my @newfiles = sort { $a eq $b } map {
        my $suffix=$_;
        my ($version, $prefix) = @{ $fileshash{ $suffix } };
        join ("", $prefix, $version, $suffix);
  } (keys %fileshash);
  #say "filtered $files=";
  #say Dumper(\@newfiles);
  return \@newfiles;
}

# begin closure
{
  my @files;
###############################################################################
# call back function to File::Find
#
###############################################################################
  sub process_sip () {
    my $file=$File::Find::name;
    if ($file =~ m/V\d+-IE\d+\.xml$/) {
      push @files, $file;
    }
    return;
  }
###############################################################################
###############################################################################
############# main ############################################################
###############################################################################
###############################################################################
  my $dir = shift @ARGV;
  if (defined $dir && -d "$dir") {
    write_database_creation();
    write_tables_creation();
    write_prepare_insert();
    find(\&process_sip, $dir);
    # find newest version of files
    my @sorted_files = sort {$a eq $b} @files;
    my $files = find_newest_iefile_version ( \@sorted_files );
    foreach my $file (@{ $files }) {
      my $ret = parse_iexml($file);
      write_addsql($ret);
    }
    write_index_creation();
  } else {
    die "no directory given on commandline"
  }
} #end closure
1;

