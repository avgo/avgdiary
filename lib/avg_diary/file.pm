package avg_diary::file;

use strict;

sub new {
	(my $class, my %cnf) = @_;

	my $filename       = delete $cnf{filename};

	die "avg_diary::file error: filename parameter needed.\n"
			if not defined $filename;

	my $self = bless {
		filename => $filename,
	}, $class;

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

	my $cur_date; my $cur_time; my $cur_record;
	my $lineno = 1; my $rec_line;
	my $tags = [ ];

	open my $fd, "<", $self->{filename} or die
			"avg_diary::file error: can't open file '$self->{filename}'. $!.\n";

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
					$rec_line,
					$lineno,
					$args,
				);

				$cur_time = $1;
				$cur_record = $_;
				$tags = [ ];
				$rec_line = $lineno;
			}
			elsif (/^ / or /^$/)
			{
				line_tags ($tags, $_, "!") if /^ *tags:/;
				$cur_record .= $_;
			}
			else
			{
				die	"avg_diary::file error: syntax error 2 at " .
					$self->{filename} . ":$lineno\n" .
					$_ . "\n";
			}
		}
		elsif ($state == STATE_REC_01)
		{
			if (/^([0-9]{2}:[0-9]{2}) /)
			{
				$cur_time = $1;
				$cur_record = $_;
				$rec_line = $lineno;

				$state = STATE_REC_02
			}
			elsif (/^$/)
			{
			}
			else
			{
				die	"avg_diary::file error: syntax error 1 at " .
					$self->{filename} . ":$lineno\n" .
					$_ . "\n";
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
			$rec_line,
			$lineno,
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
