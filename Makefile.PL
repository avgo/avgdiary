use 5.012004;
use ExtUtils::MakeMaker;

my @prog = ("avg_diary.pl");

WriteMakefile(
	NAME              => 'avg_diary',
	EXE_FILES         => [ map "bin/$_", @prog ]
#    VERSION_FROM      => 'lib/avg_diary.pm', # finds $VERSION
#    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
#    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
#      (ABSTRACT_FROM  => 'lib/avg_diary.pm', # retrieve abstract from module
#       AUTHOR         => 'A. U. Thor <avg@gentoo.org>') : ()),
);
