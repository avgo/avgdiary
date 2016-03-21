package avg_diary::add;

use strict;

sub avg_diary_add {
	(my %cnf) = @_;

	my $uptime = delete $cnf{uptime};
	my $date   = delete $cnf{date};

	my $mday; my $mon; my $year;
	my $hour; my $min;

	if ($uptime == 1)
	{
		die "error: uptime and date def.\n"
				if defined $date;

		my $uptime_data;

		$uptime_data = `uptime -s`;
		$uptime_data =~ /([0-9]+)-([0-9]+)-([0-9]+) *([0-9]+):([0-9]+):([0-9]+)/;

		($mday, $mon, $year, $hour, $min) = ($3, $2, $1, $4, $5);
	}
	elsif (defined $date)
	{
		die "error: one of uptime or date must be def.\n"
				if not defined $date;

		($mday, $mon, $year, $hour, $min) = @{$date};
	}
	else
	{
		die "error: either date or uptime must be defined.\n";
	}

	my $avg_diary_dir = avg_diary_dir_env;

	my $diary_file = $avg_diary_dir . "/" . sprintf (
			"day_%04u_%02u_%02u", $year, $mon, $mday);

	my $diary_file_old = $diary_file . ".old";

	my $lt = timelocal (0, $min, $hour, $mday, $mon - 1, $year);

	(undef, $min, $hour, $mday, $mon, $year, my $wday) = localtime $lt;

	$mon += 1; $year += 1900;

	my @wdays_str = (
		"понедельник",
		"вторник",
		"среда",
		"четверг",
		"пятница",
		"суббота",
		"воскресенье"
	);

	my $new_rec = sprintf (
		"%02u:%02u    \n" .
		"\n",
		$hour, $min
	);

	my $args = {
		data_new => sprintf (
			"%02u.%02u.%04u, %s.\n" .
			"\n"
			,
			$mday, $mon, $year,
			$wdays_str[ ( $wday + 6 ) % 7 ]
		),
		new_min  => $hour * 60 + $min,
		new_rec  => $new_rec,
	};

	if ( -f $diary_file )
	{
		unlink $diary_file_old;
		rename $diary_file, $diary_file_old;

		my $df = new avg_diary::file ( filename => $diary_file_old );

		$df->read ( sub {
			(my $date, my $time, my $rec, my $tags,
				my $rec_line, my $rec_line_e, my $args) = @_;

			(my $hh, my $mm) = $time =~ /([0-9]+):([0-9]+)/;

			my $cr_min = $hh * 60 + $mm;  # current record minutes.

			# At this condition we are looking for a record with greater time
			# than a time of a new record.
			#
			if ($args->{new_min} < $cr_min and not defined $args->{rec_line})
			{
				$args->{data_new} .= $args->{new_rec};
				$args->{rec_line}   = $rec_line;
				$args->{rec_line_e} = $rec_line_e;
			}

			$args->{data_new} .= $rec;
			$args->{last_line} = $rec_line_e;
		}, $args);
	}
	else
	{
		$args->{last_line} = 3;
	}

	if (not defined $args->{rec_line})
	{
		$args->{data_new} .= $new_rec;

		$args->{rec_line}   =  $args->{last_line};
		$args->{rec_line_e} =  $args->{rec_line} + 2;
	}

	open my $fd, ">", $diary_file or die "error: \n";

	print $fd $args->{data_new};

	close $fd;

	system sprintf (
		"vim -c 'set expandtab' -c 'normal %uGA' '%s'",
		$args->{rec_line}, $diary_file
	);
}

1;
