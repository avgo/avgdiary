package avg_diary::calendar;

use strict;
use utf8;

use Date::Calc qw(
	Add_Delta_Days
	Day_of_Week
	);
use Time::Local;

use avg_diary::avg_diary;

sub new {
	( my $class, my %cnf ) = @_ ;

	my $dayfiles = delete $cnf{dayfiles};

	die "calendar::new() error: dayfiles required for calendar!\n"
			if not defined $dayfiles;

	my $self = bless {
		dayfiles => $dayfiles
	}, $class ;
}

sub print_cal {
	( my $self, my $this_year, my $this_mon, my $this_day ) = @_ ;

	my $context = 12;
	my $dayfiles = $self->{dayfiles} ;
	my $result;

	# Date BEGIN

	(my $b_year, my $b_mon, my $b_day) =
			dayfile_name_to_date ${$dayfiles}[0] ;

	my $b_wday = Day_of_Week( $b_year, $b_mon, $b_day );

	if ( $b_wday > 1 )
	{
		( $b_year, $b_mon, $b_day ) = Add_Delta_Days (
			$b_year, $b_mon, $b_day, 1 - $b_wday
		);
		$b_wday = 1;
	}

	my $b_tl = timelocal (0, 0, 0, $b_day, $b_mon - 1, $b_year);

	# Date END

	(my $e_year, my $e_mon, my $e_day) =
			dayfile_name_to_date ${$dayfiles}[$#{$dayfiles}] ;

	my $e_wday = Day_of_Week( $e_year, $e_mon, $e_day );

	if ( $e_wday < 7 )
	{
		( $e_year, $e_mon, $e_day ) = Add_Delta_Days (
			$e_year, $e_mon, $e_day, 7 - $e_wday
		);
		$e_wday = 7;
	}

	my $e_tl = timelocal (0, 0, 0, $e_day, $e_mon - 1, $e_year);

	# This

	my $this_tl = timelocal (0, 0, 0, $this_day, $this_mon - 1, $this_year);

	my $this_wday = Day_of_Week( $this_year, $this_mon, $this_day );

	# Date BEGIN correction

	if ( int ( ( $this_tl - $b_tl ) / ( 24*60*60 ) ) > $context * 7 )
	{
		( $b_year, $b_mon, $b_day ) = Add_Delta_Days (
			$this_year, $this_mon, $this_day,
			1 - $context * 7 - $this_wday
		);
		$b_wday = 1;
	}

	# Date END correction

	if ( int ( ( $e_tl - $this_tl ) / ( 24*60*60 ) ) > $context * 7 )
	{
		( $e_year, $e_mon, $e_day ) = Add_Delta_Days (
			$this_year, $this_mon, $this_day,
			7 * ( $context + 1 ) - $this_wday
		);
		$e_wday = 7;
	}

	# DATES.

	$result .= sprintf
		"         %02u.%02u.%04u -- %02u.%02u.%04u\n" .
		"\n",
		$b_day, $b_mon, $b_year,
		$e_day, $e_mon, $e_year
	;

	$result .=
		"                             Пн  Вт  Ср  Чт  Пт  Сб  Вс\n"  .
		"         ------ ---------- -----------------------------\n" .
		"         "
	;

	$b_tl = timelocal (0, 0, 0, $b_day, $b_mon - 1, $b_year);

	my $i;

	for ( $i = 0 ; ; ++$i )
	{
		(my $cur_year, my $cur_mon, my $cur_day) =
				dayfile_name_to_date ${$dayfiles}[$i] ;

		my $cur_tl = timelocal (0, 0, 0, $cur_day, $cur_mon - 1, $cur_year);

		last if $b_tl <= $cur_tl ;
	}

	my $prec_day; my $prev_mon; my $prev_year;

	my $is_print_mon_label = 0;

	my $is_print_year_label = 0;

	my $days_line;

	while 	(($b_year < $e_year) ||
		(($b_year == $e_year) && ($b_mon < $e_mon)) ||
		(($b_year == $e_year) && ($b_mon == $e_mon) && ($b_day <= $e_day)))
	{
		(my $cur_year, my $cur_mon, my $cur_day) =
				dayfile_name_to_date ${$dayfiles}[$i] ;

		my $mark_b;
		my $mark_e;

		if ( ( $this_day == $b_day ) && ( $this_mon == $b_mon ) && ( $this_year == $b_year ) )
		{
			$mark_b = "\033[33;41;1m"; ++$i;
			$mark_e = "\033[0m";
		}
		elsif ( ( $cur_day == $b_day ) && ( $cur_mon == $b_mon ) && ( $cur_year == $b_year ) )
		{
			$mark_b = "\033[42;37m"; ++$i;
			$mark_e = "\033[0m";
		}

		$days_line .= sprintf "%s %2d %s", $mark_b, $b_day, $mark_e;

		if ( $prev_year != $b_year )
		{
			$is_print_mon_label  = 1 ;
			$is_print_year_label = 1 ;
		}
		else
		{
			$is_print_mon_label = 1
				if $prev_mon != $b_mon ;
		}

		if ( $b_wday == 7 )
		{
			if ( $is_print_year_label )
			{
				$result .= sprintf " %4d", $b_year ;

				$is_print_year_label = 0 ;
			}
			else
			{
				$result .= "     ";
			}

			$result .= " |";

			if ( $is_print_mon_label )
			{
				my @months = ( "",
					"ЯНВАРЬ  ",
					"ФЕВРАЛЬ ",
					"МАРТ    ",
					"АПРЕЛЬ  ",
					"МАЙ     ",
					"ИЮНЬ    ",
					"ИЮЛЬ    ",
					"АВГУСТ  ",
					"СЕНТЯБРЬ",
					"ОКТЯБРЬ ",
					"НОЯБРЬ  ",
					"ДЕКАБРЬ ",
				);

				$result .= sprintf " %s | ", $months[ $b_mon ] ;

				$is_print_mon_label = 0;
			}
			else
			{
				$result .= "          | ";
			}

			$result .=
				$days_line . "\n" .
				"         ";
			$days_line = "";
		}

		( $prev_year, $prev_mon ) = ( $b_year, $b_mon );

		( $b_year, $b_mon, $b_day ) = Add_Delta_Days ( $b_year, $b_mon, $b_day, 1);
		$b_wday = Day_of_Week( $b_year, $b_mon, $b_day );
	}

	$result .= "\n\n";

	return $result;
}


1;
