package avg_diary::file;

use strict;

sub new {
	(my $class, my %cnf) = @_;

	my $avg_diary_dir  = delete $cnf{avg_diary_dir};

	die "avg_diary_dir is required.\n" if not defined $avg_diary_dir;

	die "avg_diary_dir path '$avg_diary_dir' is not valid directory.\n"
		if not defined $avg_diary_dir;

	my $date           = delete $cnf{date};
	my $filename       = delete $cnf{filename};

	my $day; my $month; my $year;

	if ($date =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)$/)
	{
		($day,$month,$year) = ( $1, $2, $3 );
		$filename = sprintf "day_%04u_%02u_%02u",
				$year, $month, $day;
	}
	elsif ($filename =~ /^day_([0-9]+)_([0-9]+)_([0-9]+)$/)
	{
		($day,$month,$year) = ( $3, $2, $1 );
	}
	else
	{
		die "error: 1.\n";
	}

	my $self = bless
		{
			avg_diary_dir  => $avg_diary_dir,
			day            => $day,
			month          => $month,
			year           => $year,
			filename       => $filename,
		},
		$class;

	return $self;
}

use constant {
	STATE_DATE    => 1,
	STATE_REC_01  => 2,
	STATE_REC_02  => 3,
};

sub read {
	(my $self, my $proc, my $args) = @_;

	my $state = STATE_DATE;
	my $dayfile_rp = $self->{avg_diary_dir} . "/" . $self->{filename};

	my $cur_date; my $cur_time; my $cur_record;
	my $lineno = 1;
	my $tags = [ ];

	open my $fd, "<", $dayfile_rp or die
			"error: '$dayfile_rp'. $!.\n";

	while (<$fd>)
	{
		if ($state == STATE_REC_02)
		{
			if (/^([0-9]{2}:[0-9]{2}) /)
			{
				&{$proc} (
					$cur_date,
					$cur_time,
					$cur_record,
					$tags,
					$args,
				);

				$cur_time = $1;
				$cur_record = $_;
				$tags = [ ];
			}
			elsif (/^ / or /^$/)
			{
				line_tags ($tags, $_, "!") if /^ *tags:/;
				$cur_record .= $_;
			}
			else
			{
				die "syntax error 2 at $lineno\n" .
					$_ . "\n";
			}
		}
		elsif ($state == STATE_REC_01)
		{
			if (/^([0-9]{2}:[0-9]{2}) /)
			{
				$cur_time = $1;
				$cur_record = $_;
				$state = STATE_REC_02
			}
			elsif (/^$/)
			{
			}
			else
			{
				die "syntax error 1 at $lineno\n";
			}
		}
		elsif ($state == STATE_DATE)
		{
			if (/^[0-9]{2}\.[0-9]{2}\.[0-9]+/)
			{
				$cur_date = $_;
				$state = STATE_REC_01;
			}
		}

		++$lineno;
	}

	close $fd;

	if ($state == STATE_REC_02)
	{
		&{$proc} (
			$cur_date,
			$cur_time,
			$cur_record,
			$tags,
			$args,
		);
	}
}

sub line_tags {
	(my $tags_h, my $line, my $comment) = @_;

	chomp $line;

	$line =~ s/^ *tags: *//g;

	while ($line ne "") {
		if ( ! ($line =~ s/^\[([^\]]*)\][, ]*//)) {
			printf "%s:некорректное определение тега: |%s|%s|\n", $comment, $1, $line;
			$line = "";
		}
		elsif ($1 eq "") {
			printf "пустой тег\n";
		}
		else {
			push @{$tags_h}, $1;
		}
	}
}

1;
