package Puppet::Storage ;

use Carp ;
use AutoLoader 'AUTOLOAD' ;

use strict ;
use vars qw($VERSION %ClassData) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

%ClassData = (dbHash => undef, keyRoot => undef );

# translucent attribute (See Tom Christiansen's perltootc page)
# creates accessor methods for all keys of ClassData.
for my $datum (keys %ClassData)
  {
    no strict "refs";
    *$datum = sub 
      {
        my $self = shift ;
        my $class = ref($self) || $self ;
        unless (ref($self))
          {
            $ClassData{$datum} = shift if @_ ;
            return $ClassData{$datum} ;
          }
        $self->{$datum} = shift if @_ ;
        return defined $self->{$datum} ? $self->{$datum} : $ClassData{$datum};
      }
  }

sub new 
  {
    my $type = shift ;
    my $self = {} ;
    my %args = @_ ;
    
    bless $self,$type ;

    local $_ ;

    croak("You must pass a name to Puppet::Storage") 
          unless defined $args{name};

    $self->{name}=$args{name} ;

    foreach (qw/dbHash keyRoot/)
      {
        $self->{$_} = delete $args{$_} ;
        croak "You must define $_ to Puppet::Storage $self->{name}"
          unless defined $self->$_() ;
      }

    $self->{myDbKey} = $self->keyRoot.";".$self->{name} ;

    return $self;
  }

1;

__END__

=head1 NAME

Puppet::Storage - Utility class to handle permanent data

=head1 SYNOPSIS

 use Puppet::Storage ;

 my $file = 'test.db';
 my %db;

 # you manage the DB file
 tie %db, 'MLDBM', $file , O_CREAT|O_RDWR, 0640 or die $! ;

 # translucent attributes
 Puppet::Storage->dbHash(\%db);
 Puppet::Storage->keyRoot('key root');

 my $foo = new Puppet::Storage (name => 'foo');
 my $bar = new Puppet::Storage (name => 'bar');

 # store some data in permanent storage
 $foo->storeDbInfo(toto => 'toto val', dummy => 'null') ;

 # remove some data from permanent storage
 $bar->deleteDbInfo('dummy');

 # at the end of your program, just to be on the safe side
 untie %dbhash ;

=head1 DESCRIPTION

Puppet::Storage is a utility class which provides a facility to store data 
on a database file tied to a hash.(with L<MLDBM>)

=head1 Class data

These items are translucent attributes (See L<perltootc> by Tom Christiansen).

Using the following method, you may set or query the value for the data
class. And these parameters may be overridden with the constructor or by
invoking this method by the object rather than by the class.

=over 4

=item keyRoot

See L<"Database management">.

=item dbHash

ref of the tied hash. See L<"Database management">.

=back

=head1 Constructor

=head2 new(...)

Creates new Puppet::Storage object. New() parameters are:

=over 4

=item name

The name of your object (no defaults)

=back

=head2 spawn(...)

Spawn a new Puppet::Storage object re-using the translucent attribute
of the spawner object.

parameters are:

=over 4

=item name

The name of your object (no defaults)

=back

=head2 child(...)

Spawn a new Puppet::Storage object re-using the translucent attribute
of the spawner object. On top of that a new keyRoot attribute is defined
as '<parent_keyroot child_name';

E.g. if the parent keyroot is 'foo', the parent name is 'bar', the
child name is 'calvin', then the new keyRoot of the child is set to
'foo bar'. So for instance a 'toto' data will be stored in the child
with this key: 'foo bar;calvin#toto'. That's pretty complex,
fortunately, you shouldn't have to worry about the key managment.

parameters are:

=over 4

=item name

The name of your object (no defaults)

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

sub spawn
  {
    my $self = shift ;
    my %args = @_ ;

    croak "No name passed to $self->{name}::spawn\n" unless 
      defined $args{name};

    my %new ;

    #optionnal, we may rely on the .fmrc
    foreach my $k (keys %ClassData)
      {
        my $v = $args{$k} || $self->{$k} ;
        $new{$k} = $v if defined $v ;
      }
    
    return ref($self)->new 
      (
       name => $args{name},
       %new
      ) ;
  }

sub child
  {
    my $self = shift ;
    my %args = @_ ;

    $args{keyRoot} = $self->keyRoot().' '.$self->{name} ;
    return $self->spawn(%args) ;
  }

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
        $self->dbHash()->{$valdbkey} = $h->{$hkey} ; # register it in MLDBM
      }
  }

sub deleteDbInfo
  {
    my $self = shift ;
    my @args = @_ ;

    foreach my $hkey (@args)
      {
        my $valdbkey = $self->{myDbKey}."# $hkey";
        delete $self->dbHash()->{$valdbkey};
      }
  }

sub getDbInfo
   {
     my $self = shift ;
     local $_;
     if (scalar @_ == 1)
       {
         my $key = shift ;
         my $valdbkey = $self->{myDbKey}."# $key";
         return $self->dbHash()->{$valdbkey} ;
       }
     else
       {
         #print "@keys\n",@{$self->dbHash()}{@keys},"\n";
         my %h ;
         foreach (@_)
           {
             my $key = $self->{myDbKey}."# $_" ;
             $h{$_} = $self->dbHash()->{$key} if defined $self->dbHash()->{$key};
           }
         #print  @h{@_},"\n";
         return \%h;
       }
   }

sub dumpDbInfo
  {
     my $self = shift ;
     my %h ;

     my $pat = $self->{myDbKey} .'# ';
     
     local $_;
     foreach (keys %{$self->dbHash()})
       {
         my $key = $_ ;
         $h{$key}=$self->dbHash()->{$_} if $key =~ s/$pat//;
       }

     return \%h;
  }

1;
