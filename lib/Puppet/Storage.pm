package Puppet::Storage ;

use Carp ;
use AutoLoader 'AUTOLOAD' ;

use strict ;
use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

my $_index = 1 ;

sub new 
  {
    my $type = shift ;
    my $self = {} ;
    my %args = @_ ;
    
    $self->{name}= $args{name} || 'anonymous'.$_index++ ;

    foreach (qw/dbHash keyRoot/)
      {
        croak("You must pass parameter $_ to Puppet::Storage:: new $self->{name}\n") 
          unless defined $args{$_};
        $self->{$_} = delete $args{$_} ;
      }


    bless $self,$type ;

    $self->{myDbKey} = $self->{keyRoot}.";".$self->{name} ;

    return $self;
  }

1;

__END__

=head1 NAME

Puppet::Storage - Utility class to handle permanent data

=head1 SYNOPSIS

 use Puppet::Storage ;

 package myClass ;
 sub new
  {
    my $type = shift ;
    my $self = {};
    $self->{storage} = new Puppet::Storage(@_) ;
    bless $self,$type ;
  }

 package main ;

 # create a class with no persistent data
 my $foo = new myClass (Name => 'foo') ;

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

Puppet::Storage is a utility class which provides a facility to store data 
on a database file tied to a hash.(with L<MLDBM>)


=head1 Constructor

=head2 new(...)

Creates new Puppet::Storage object. New() parameters are:

=over 4

=item name

The name of your object (defaults to "anonymous1" or "anonymous2" ...)

=item keyRoot

See L<"Database management">.

=item dbHash

ref of the tied hash. See L<"Database management">.

=back

=head1 Database management

The class is designed to store its data in a database file. (For this
you should use MLDBM if you want to store more than a scalar in the
database). The key for this entry is "$keyRoot;$name# $key". keyRoot
and name being passed to the constructor of the object and 'key' is
the name of the value you want to store (This may remind perl old
timers of a trick to emulate multi-dimensional hashes in perl4)

Needless to say, creating two instances of Puppet::Storage with the
same dbHash, keyRoot and name is a I<bad> idea because you may mix up
data from one object to another.

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

=head2 dumpDbInfo()

dumpDbInfo will return a hash ref containing a copy of all the
permanent data of this object. 

Using this method should only be used for debug purpose as it will
iterate over all the other values of the DB_File to get the data of
this object.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Puppet::Body>

=cut

### Methods to handle permanent data storage

sub setName
  {
    my $self = shift;
    my $name = shift;

    if (defined $name)
      {
        $self->{name}=$name;
      } 
    else
      {
        die "Puppet::Storage::setName: missing 'name' parameter\n";
      }
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

sub dumpDbInfo
  {
     my $self = shift ;
     my %h ;

     my $pat = $self->{myDbKey} .'# ';
     
     foreach (keys %{$self->{dbHash}})
       {
         my $key = $_ ;
         $h{$key}=$self->{dbHash}{$_} if $key =~ s/$pat//;
       }

     return \%h;
  }

1;
