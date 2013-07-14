use 5.012004;
use ExtUtils::MakeMaker;

my @prog = ("avg_diary.pl");

WriteMakefile(
	NAME              => 'avg_diary',
	EXE_FILES         => [ map "bin/$_", @prog ]
);
