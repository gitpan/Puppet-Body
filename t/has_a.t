# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.


# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use Puppet::Body ;
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;

package MyTest ;

sub new
  {
    my $type = shift ;
    my $self = {};
    my %args = @_ ;
    $self->{name}=$args{name};
    $self->{body} = new Puppet::Body(cloth => $self, @_) ;

    bless $self,$type ;
  }

sub body { return shift->{body} ;}

sub addChildren
  {
    my $self = shift ;

    # create myself some children
    foreach my $n (qw/albert charlotte raymond spirou zorglub/)
      {
        my $obj = new MyTest (name => $n);
        $self->{body}->acquire(body => $obj->body);
      }
  }

sub action { return "Hi ".shift->{name};}

package main ;

my $test = new MyTest(name => 'under_test') ;
print "ok ",$idx++,"\n";

# add tests for all kinds of relations (diamonds .. and so on)
$test->addChildren() ;

print "not " unless join(" ",sort map($_->{name},$test->body->getContent())) 
  eq "albert charlotte raymond spirou zorglub";
print "ok ",$idx++,"\n";

$test->body->drop('raymond');
print "not " unless join(" ",$test->body->contentNames)
  eq "albert charlotte spirou zorglub";
print "ok ",$idx++,"\n";

my $common = new MyTest(name => 'common') ;
my $unknown = new MyTest() ;

my $albertb = $test->body->getContent('albert');
$albertb -> acquire(body => $common->body) ;
print "not " unless join(" ",$albertb->contentNames) eq "common";
print "ok ",$idx++,"\n";

my $charlotteb = $test->body->getContent('charlotte');
$charlotteb-> acquire(body => $common->body) ;
$charlotteb-> acquire(body => $unknown->body) ;
print "not " unless  join(" ",$charlotteb->contentNames) 
  eq "anonymous1 common";
print "ok ",$idx++,"\n";

$charlotteb-> drop('common') ;
print "not " unless   join(" ",,$charlotteb->contentNames) eq "anonymous1";
print "ok ",$idx++,"\n";

$albertb-> drop('common') ;

print scalar $common->body->getContainer() ? "not " : '' ;
print "ok ",$idx++,"\n";

# perform an action on content
my $tb = $test->body->getContent('zorglub')->cloth;
print "not " unless  $tb ->action eq "Hi zorglub";
print "ok ",$idx++,"\n";

# perform an action on all contents
print "not " unless  join(' ',map($_->cloth->action,$test->body->getContent()))
  eq "Hi spirou Hi albert Hi zorglub Hi charlotte";
print "ok ",$idx++,"\n";

# perform an action on a container
print "not " unless  $tb->body->getContainer('under_test')->cloth->action
  eq "Hi under_test";

print "ok ",$idx++,"\n";
