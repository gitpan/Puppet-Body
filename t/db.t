# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}
use Fcntl ;
use MLDBM qw(DB_File) ;
use ExtUtils::testlib;
use Puppet::Body ;
use Puppet::Storage;
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";#1
my $trace = shift || 0;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;
my $file = 'test.db';
my %dbhash;
tie %dbhash,  'MLDBM',    $file , O_CREAT|O_RDWR, 0640 or die $! ;
print "ok ",$idx++,"\n";#2

Puppet::Storage->dbHash(\%dbhash) ;
Puppet::Storage->keyRoot('key root') ;
my $test2 = new Puppet::Storage 
  (
   name => 'test2'
  );

print "ok ",$idx++,"\n";#3

$test2->storeDbInfo(toto => 'toto val', 
                 'titi' => 'titi val',
                   dummy => 'null') ;
print "ok ",$idx++,"\n";#6

print "not " unless $test2->getDbInfo('toto') eq "toto val" ;
print "ok ",$idx++,"\n";#7

my $h = $test2->getDbInfo('toto','titi','dummy');
print "not " unless ($h->{toto} eq 'toto val'
                     and $h->{titi} eq 'titi val'
                     and $h->{dummy} eq 'null') ;

print "ok ",$idx++,"\n";#8

# test  to do
$h = $test2->dumpDbInfo();
print "not " unless ($h->{toto} eq 'toto val'
                     and $h->{titi} eq 'titi val'
                     and $h->{dummy} eq 'null') ;
print "ok ",$idx++,"\n";#9


$test2->deleteDbInfo('dummy');
print "ok ",$idx++,"\n";#10


print "not " unless 
  ($dbhash{'key root;test2# titi'} eq 'titi val' and
   $dbhash{'key root;test2# toto'} eq 'toto val') ;

print "ok ",$idx++,"\n";#11

my $test3=$test2->spawn(name => 'test3');
print "not " unless defined $test3 ;
print "ok ",$idx++,"\n";

$test3->storeDbInfo(toto => 'toto val for 3') ;
print "ok ",$idx++,"\n";#6

print "not " unless 
  ($dbhash{'key root;test3# toto'} eq 'toto val for 3') ;

print "ok ",$idx++,"\n";#11

my $test4=$test2->spawn(name => 'test4', keyRoot => 'another key');
print "not " unless defined $test4 ;
print "ok ",$idx++,"\n";

$test4->storeDbInfo(toto => 'toto val for 4') ;
print "ok ",$idx++,"\n";#6

print "not " unless 
  ($dbhash{'another key;test4# toto'} eq 'toto val for 4') ;

print "ok ",$idx++,"\n";#11

my $test5=$test2->child(name => 'test5');
print "not " unless defined $test5 ;
print "ok ",$idx++,"\n";

$test5->storeDbInfo(toto => 'toto val for 5') ;
print "ok ",$idx++,"\n";#6

print "not " unless 
  ($dbhash{'key root test2;test5# toto'} eq 'toto val for 5') ;

print "ok ",$idx++,"\n";#11


untie %dbhash ;


#unlink $file;
