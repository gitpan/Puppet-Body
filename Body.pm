############################################################
#
# $Header: /mnt/barrayar/d06/home/domi/Tools/perlDev/Puppet_Body/RCS/Body.pm,v 1.13 1999/02/05 12:11:22 domi Exp $
#
# $Source: /mnt/barrayar/d06/home/domi/Tools/perlDev/Puppet_Body/RCS/Body.pm,v $
# $Revision: 1.13 $
# $Locker:  $
# 
############################################################

package Puppet::Body ;

use Carp ;
use AutoLoader 'AUTOLOAD' ;
use Puppet::LogBody ;

use strict ;
use vars qw($VERSION $_index) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/;
$_index = 1 ;

sub new 
  {
    my $type = shift ;
    my $self = {} ;
    my %args = @_ ;
    
    foreach (qw/name dbHash keyRoot cloth/)
      {
        $self->{$_} = delete $args{$_} ;
      }

    $self->{name}='anonymous'.$_index++ unless defined $self->{name} ;
    die "no 'cloth' parameter defined for body $self->{name}\n" unless
      defined $self->{cloth};

    bless $self,$type ;

    # If permanent data is used, I must check some parameters
    $self->_checkDbParameters() 
      if (defined $self->{dbHash} or defined $self->{keyRoot}) ;

    $self->_createLogs($args{how}) ;

    return $self;
  }

sub cloth { return shift->{cloth};}

sub _createLogs
  {
    my $self = shift ;
    my $how = shift ;

    # config debug window
    foreach (qw/debug event/)
      {
        my $what = $_ ;
        $self->{'log'}{$_} = new Puppet::LogBody
          (
           name => $_,
           how => $how
          );
      }
  }

1;

__END__

=head1 NAME

Puppet::Body - Utility class to handle permanent data, has-a relations and logs

=head1 SYNOPSIS

 use Puppet::Body ;

 package myClass ;
 sub new
  {
    my $type = shift ;
    my $self = {};
    $self->{body} = new Puppet::Body(cloth => $self, @_) ;
    bless $self,$type ;
  }

 sub body { return shift->{body} ;}

 package main ;

 # create a class with no persistent data
 my $foo = new myClass (Name => 'foo') ;

 # foo now has baz and buz
 $foo->body->acquire(body => $baz);
 $foo->body->acquire(body => $buz);

 # foo no longer has $baz
 $foo->body->drop($baz);

 # create a class with persistent data
 my $file = 'test.db';
 my %dbhash;
 # you manage the DB file
 tie %dbhash, 'MLDBM', $file , O_CREAT|O_RDWR, 0640 or die $! ;

 my $test = new myClass 
   (
    name => 'test',
    dbHash => \%dbhash,
    keyRoot => 'key root'
   );

 # store some data in permanent storage
 $test->storeDbInfo(toto => 'toto val', dummy => 'null') ;

 # remove some data from permanent storage
 $test->deleteDbInfo('dummy');

 # at the end of your program, just to be on the safe side
 untie %dbhash ;

=head1 DESCRIPTION

Puppet::Body is a utility class that is used (and not inherited like
the deprecated Puppet::Any) to manage dynamic has-a relations between objects.

This class provides the following features :

=over 4

=item *

An event log display so user object may log their activity (with
L<Puppet::LogBody>)

=item *

A Debug log display so user object may log their "accidental"
activities(with
L<Puppet::LogBody>)


=item *

A set of functions to managed "has-a" relationship between Puppet objects.

=item *

A facility to store data on a database file tied to a hash.(with L<MLDBM>)

=back

=head1 Constructor

=head2 new(...)

Creates new Puppet object. New() parameters are:

=over 4

=item name

The name of your object (defaults to "anonymous1" or "anonymous2" ...)

=item cloth

The ref of your object

=item keyRoot

See L<"Database management">.

=item dbHash

ref of the tied hash. See L<"Database management">.

=item how

Specify how logs are to be handled. See L<Puppet::LogBody/"Constructor">

=back

=head1 Generic methods

=head2 getName()

Returns the name of this object.

=head1 HAS-A relations management methods

=head2 acquire(...)

Acquire the object ref as a child. Parameters are:

=over 4

=item body

Reference of the Puppet::Body object that is to be acquired.

=item name

Name to refer to the acquired Puppet::Body. Defaults to the name of the 
acquired Puppet::Body object.

=back

For instance if object foo acquires object bar, bar becomes part of
foo's content and foo is one of the container of bar.

=cut

#'

=head2 drop('name')

Does the opposite of acquire(), i.e. drop the object named 'name'.

=head2 getContent('name',...)

In scalar context, it returns the Puppet::Body ref of the object 'name'. 
Returns undef if 'name' is not part of the content (i.e if it has not been
'acquired' before)

In array context, it returns an array of all Puppet::Body references of all
passed names. Returns () if the object has no content.

=head2 getContainer('name',...)

Same as getContent for the container.

=head2 contentNames()

Returns all names of the content, i.e. of all 'acquired' objects.

=head2 containerNames()

Returns all names of the containers, i.e. of all objects that 'acquired' this
object

=head1 Log management.


=head2 printDebug(text)

Will log the passed text into the debug and events log object.

=head2 printEvent(text)

Will log the passed text into the events log object.

=head1 Database management

The class is designed to store its data in a 
database file. (For this you should use MLDBM if you want to store
more than a scalar in the database). The key for this entry is
"$keyRoot;$name# $key". keyRoot and name being passed to the constructor of
the object and 'key' is the name of the value you want to store
(This may remind perl old timers of a trick to emulate
multi-dimensional hashes in perl4)

Needless to say, creating two instances
of Puppet::Body with the same keyRoot and name is a I<bad> idea because you 
may mix up data from one object to another.

=head2 storeDbInfo(%hash)

Store the passed hash in the database. You may also pass a hash ref as single
argument.

=head2 deleteDbInfo(key,...)

delete the "key" entries from the database.

=head2 getDbInfo(key,...)

If one key is specified, getDbInfo will return the value of the "key"
entry from the database.

If more than one key is passed, getDbInfo will return a hash ref containing
a copy of the key,value pairs from the database.

=head1 About Puppet body classes

Puppet classes are a set of utility classes which can be used by any object.
If you use directly the Puppet::Body class, you get the plain functionnality.
And if you use the Puppet::Show class, you can get the same functionnality and
a Tk Gui to manage it. 

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Puppet::Log(3), Puppet::Show(3)

=cut

### Generic Methods
sub getName
  {
    return shift->{name} ;
  }

### Methods to handle HAS-A relations

sub acquire
  {
    my $self = shift ;
    my %args = @_ ;

    my $ref = $args{body}  ; # $ref must be Puppet::Body. 
    croak "$self->{name}->acquire: No body ref passed\n" unless defined $ref ;

    my $name = $args{name} || $ref->getName();

    if (defined $self->{content}{$name})
      {
        croak "Can't acquire twice the object named $name\n";
      }

    carp "Warning $name is not (or is not derived from) a Puppet::Body\n" 
      unless $ref->isa('Puppet::Body');

    $self->{content}{$name}=$ref ;
    $ref->acquiredBy($self) ;
    return $ref ;
  }

sub dropAll
  {
    my $self = shift ;
    
    my @array = sort keys %{$self->{content}} ;
    # beware that drop will delete $self->{content}
    $self->drop(@array);
  }  

# internal
sub acquiredBy
  {
    my $self = shift ;
    my $ref  = shift ;
    # the key is the ref evaluated in string context (i.e HASH(0x...)
    my $name = $ref->getName();
    $self->{container}{$name} = $ref ;
  }

sub drop
  {
    my $self = shift ;

    foreach (@_)
      {
        next unless defined $self->{content}{$_} ;
        $self->{content}{$_} -> droppedBy($self) ;
        delete $self->{content}{$_} ;
      }
  }

#internal
# return 1 if this class still have containers
sub droppedBy
  {
    my $self = shift ;
    my $ref = shift;

    my $name = $ref->getName();
    delete $self->{container}{$name} ;

    return 1 if scalar %{$self->{container}} ;

    # suicide if I have no more father
    if (defined $self->{content})
      {
        foreach (values %{$self->{content}}) {$_ -> droppedBy($self)};
      } 
    return 0;
  }

sub getContent
  {
    my $self = shift ;
    return wantarray ? () : undef     unless defined $self->{content};
    return values %{$self->{content}} if scalar @_ == 0;
    return @{$self->{content}}{@_}    if wantarray; # slice of hash
    return $self->{content}{$_[0]} ;
  }

sub contentNames
  {
    my $self = shift ;
    return defined $self->{content} ? sort keys %{$self->{content}} : ();
  }

sub getContainer
  {
    my $self = shift ;
    return wantarray ? () : undef       unless defined $self->{container};
    return values %{$self->{container}} if scalar @_ == 0;
    return @{$self->{container}}{@_}    if wantarray; # slice of hash
    return $self->{container}{$_[0]} ;
  }

sub containerNames
  {
    my $self = shift ;
    return defined $self->{container}? sort keys %{$self->{container}} : ();
  }

### Methods to handle logs

sub printDebug
  {
    my $self= shift ;
    my $text=shift ;
    $self->{'log'}{debug}  ->log($text) ;
    $self->{'log'}{'event'}->log($text) ;
  }

sub printEvent
  {
    my $self= shift ;
    my $text=shift ;
    $self->{'log'}{'event'}->log($text) ;
  }

### Methods to handle permanent data storage

sub _checkDbParameters
  {
    my $self = shift ;

    foreach (qw/name dbHash keyRoot/)
      {
        croak("You must pass parameter $_ to $type $self->{name}\n") 
          unless defined $self->{$_};
      }
    $self->{myDbKey} = $self->{keyRoot}.";".$self->{name} ;
  }

sub storeDbInfo
  {
    my $self = shift ;
    my $h ;
    if (scalar(@_) == 1) {$h = shift ;}
    else {%$h = @_ ;}
    
    foreach my $hkey (keys %$h)
      {
        my $valdbkey = $self->{myDbKey}."# $hkey";
        $self->{dbHash}{$valdbkey} = $h->{$hkey} ; # register it in MLDBM
      }
  }

sub deleteDbInfo
  {
    my $self = shift ;
    my @args = @_ ;

    foreach my $hkey (@args)
      {
        my $valdbkey = $self->{myDbKey}."# $hkey";
        delete $self->{dbHash}{$valdbkey};
      }
  }

sub getDbInfo
   {
     my $self = shift ;
     if (scalar @_ == 1)
       {
         my $key = shift ;
         my $valdbkey = $self->{myDbKey}."# $key";
         return $self->{dbHash}{$valdbkey} ;
       }
     else
       {
         my @keys = map ($self->{myDbKey}."# $_",@_);
         #print "@keys\n",@{$self->{dbHash}}{@keys},"\n";
         my %h ;
         @h{@_} = @{$self->{dbHash}}{@keys};
         #print  @h{@_},"\n";
         return \%h;
       }
   }

