# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Fcntl ;
use MLDBM qw(DB_File) ;
use ExtUtils::testlib;
use Puppet::Body ;
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";
my $trace = shift || 0;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;
my $file = 'test.db';
my %dbhash;
tie %dbhash,  'MLDBM',    $file , O_CREAT|O_RDWR, 0640 or die $! ;
print "ok ",$idx++,"\n";

my $tv = $trace ? 'debug' : undef ;
my $test = new Puppet::Body (name => 'test',
                             dbHash => \%dbhash,
                             keyRoot => 'key root',
                             cloth => {}, # dummy object
                             trace => $tv
                            );
print "ok ",$idx++,"\n";

$test->printEvent("Dummy event print");
print "ok ",$idx++,"\n";

$test->printDebug("Dummy debug print");
print "ok ",$idx++,"\n";

$test->storeDbInfo(toto => 'toto val', 
                 'titi' => 'titi val',
                   dummy => 'null') ;
print "ok ",$idx++,"\n";

print "not " unless $test->getDbInfo('toto') eq "toto val" ;
print "ok ",$idx++,"\n";

my $h = $test->getDbInfo('toto','titi','dummy');
print "not " unless ($h->{toto} eq 'toto val'
                     and $h->{titi} eq 'titi val'
                     and $h->{dummy} eq 'null') ;

print "ok ",$idx++,"\n";

$test->deleteDbInfo('dummy');
print "ok ",$idx++,"\n";

untie %dbhash ;

my $res = `db_dump -p $file`;

print "not " unless 
  index ($res ,'key root;test# titi
titi val
key root;test# toto
toto val
') != -1 ;

print "ok ",$idx++,"\n";

#unlink $file;
