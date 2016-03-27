package avg_diary::avg_diary;

use strict;

sub new {
	(my $class, my %cnf) = @_;

	my $avg_diary_dir = delete $cnf{avg_diary_dir};

	die	$class . "->new() error: 'avg_diary_dir' parameter is unset.\n"
		if not defined $avg_diary_dir;

	die	$class . "->new() error: invalid 'avg_diary_dir' parameter.\n" .
		"'avg_diary_dir' parameter must be a valid directory.\n"
		if not -d $avg_diary_dir;

	my $self = bless {
		avg_diary_dir => $avg_diary_dir,
	}, $class;

	return $self;
}

sub day_filename {
	(my $self, my $year, my $month, my $day) = @_;

	my $file = $self->{avg_diary_dir} . "/" . sprintf (
			"day_%04u_%02u_%02u", $year, $month, $day);

	return $file;
}

1;
