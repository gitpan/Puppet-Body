use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	   => 'Puppet::Body',
   'VERSION' => '1.016',
   'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
   ($] >= 5.005 ?
    (ABSTRACT   => 'Framework to handle permanent data, has-a relations and logs',
     AUTHOR     => 'Dominique Dumont (domi@barrayar.grenoble.hp.com)') : ()),
   'PREREQ_PM' =>
   {
    'Puppet::LogBody' => '1.001',
    'MLDBM' => 0,
    'DB_File' => 0
   }
  );
