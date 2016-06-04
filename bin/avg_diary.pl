#!/usr/bin/env perl

#
# avg-diary - program for text diaries with tags.
# Anton Goncharov, 2013 - 2016.
#

BEGIN {
	my $debug = 0;
	@INC = ("./lib", @INC) if $debug == 1;
}

use strict;

use Cwd qw(abs_path);
use Data::Dumper;

use avg_diary::add;
use avg_diary::avg_diary;
use avg_diary::calendar;
use avg_diary::file;
use avg_diary::tags::dirtags;




use constant {
	PARSE_OPT_OPTREQ => 1,
	PARSE_OPT_REQ    => 2,
	PARSE_OPT_SET    => 4,
};




sub action_add;
sub action_edit;
sub action_view;
sub avg_diary_add;
sub avg_diary_dir_env;
sub avg_diary_file_check_tags;
sub date_check_dmy;
sub date_check_hm;
sub date_correction_year;
sub parse_options;
sub print_usage;




my $mark_red = "\033[31m";
my $mark_green = "\033[32m";
my $mark_e = "\033[0m";




sub action_add {
	my $param_dd;
	my $param_mon;
	my $param_yyyy;

	my $param_hh;
	my $param_min;

	my $param_uptime;

	while ($_ = shift @_)
	{
		if ($_ eq "--uptime")
		{
			die "error: uptime is already set!\n"
					if $param_uptime == 1;
			die "error: only uptime or date can be set!\n"
					if defined $param_dd;
			die "error: only uptime or time can be set!\n"
					if defined $param_hh;
			$param_uptime = 1;
		}
		elsif (/^([0-9]{1,2})\.([0-9]{1,2})(\.([0-9]{1,4}))?$/)
		{
			die "error: only uptime or date can be set!\n"
					if $param_uptime == 1;
			die "error: date is already defined!\n"
					if defined $param_dd;
			($param_dd, $param_mon, $param_yyyy) = ($1, $2, $4);
		}
		elsif (/^([0-9]{1,2}):([0-9]{1,2})$/)
		{
			die "error: only uptime or date can be set!\n"
					if $param_uptime == 1;
			die "error: time is already set!\n"
					if defined $param_hh;
			($param_hh, $param_min) = ($1, $2);
		}
		else
		{
			die "error: unknown parameter '$_'.\n";
		}
	}

	(	my $now_sec,  my $now_min,  my $now_hour,
		my $now_mday, my $now_mon,  my $now_year,
		my $now_wday, my $now_yday, my $now_isdst) = localtime;

	$now_mon  += 1;
	$now_year += 1900;

	if (defined $param_dd)
	{
		#   avg-diary add 01.02.2011       -- error! Maybe add an empty record?

		die "error: empty times is not supported.\n"
				if not defined $param_hh;

		#   avg-diary add 01.02.2011 11:01

		if ( defined $param_yyyy )
		{
			date_correction_year \$param_yyyy;
		}
		else
		{
			$param_yyyy = $now_year;
		}

		date_check_dmy $param_yyyy, $param_mon, $param_dd;
		date_check_hm $param_hh, $param_min;
	}
	elsif (defined $param_uptime)
	{
		#   avg-diary add --uptime

		my $uptime_data;

		$uptime_data = `uptime -s`;
		$uptime_data =~ /([0-9]+)-([0-9]+)-([0-9]+) *([0-9]+):([0-9]+):([0-9]+)/;

		($param_dd, $param_mon, $param_yyyy, $param_hh, $param_min) =
		(
			$3, $2, $1, $4, $5
		);
	}
	else
	{
		#   avg-diary add

		#   or

		#   avg-diary add 10:00

		$param_dd   = $now_mday;
		$param_mon  = $now_mon;
		$param_yyyy = $now_year;

		if (defined $param_hh)
		{
			#   avg-diary add 10:00

			date_check_hm $param_hh, $param_min;
		}
		else
		{
			#   avg-diary add

			$param_hh  = $now_hour;
			$param_min = $now_min;
		}
	}

	my $avg_diary = avg_diary::avg_diary->new(
		avg_diary_dir => avg_diary_dir_env
	);

	my $tags = avg_diary::tags::dirtags->new;

	$tags->read_tags_from_dir ( $avg_diary->get_tags_dir );

	my $file = $avg_diary->day_filename(
		$param_yyyy, $param_mon, $param_dd
	);

	my %cnf =
	(
		date => [
			$param_dd,
			$param_mon,
			$param_yyyy,
			$param_hh,
			$param_min,
		],
		file => $file,
	);

	avg_diary_add %cnf;

	avg_diary_file_check_tags $tags, $file;
}

sub action_edit {
	my $param_day;
	my $param_mon;
	my $param_year;

	while ($_ = shift @_)
	{
		if (/^([0-9]{1,2})\.([0-9]{1,2})(\.([0-9]{1,4}))?$/)
		{
			die "error: date is already defined!\n"
					if defined $param_day;
			($param_day, $param_mon, $param_year) = ($1, $2, $4);
		}
		else
		{
			die "error: unknown parameter '$_'.\n";
		}
	}

	(	undef, undef, undef,
		my $now_mday, my $now_mon, my $now_year) = localtime;

	$now_mon  += 1;
	$now_year += 1900;

	my $is_today;

	if (defined $param_day)
	{
		if ( defined $param_year )
		{
			date_correction_year \$param_year;
		}
		else
		{
			$param_year = $now_year;
		}

		date_check_dmy $param_year, $param_mon, $param_day;

		$is_today = 0;
	}
	else
	{
		($param_day, $param_mon, $param_year) = (
			$now_mday, $now_mon, $now_year
		);

		$is_today = 1;
	}

	my $avg_diary = avg_diary::avg_diary->new(
		avg_diary_dir => avg_diary_dir_env
	);

	my $tags = avg_diary::tags::dirtags->new;

	$tags->read_tags_from_dir ( $avg_diary->get_tags_dir );

	my $file = $avg_diary->day_filename(
		$param_year, $param_mon, $param_day
	);

	if ( not -f $file )
	{
		my $message;
		my $add_param;

		if ($is_today)
		{
			$message = "сегодня";
			$add_param = "\n";
		}
		else
		{
			my @months = (
				"января",  "февраля", "марта",
				"апреля",  "мая",     "июня",
				"июля",    "августа", "сентября",
				"октября", "ноября",  "декабря"
			);

			$message   = sprintf
					"%u %s %u года"
					,
					$param_day, $months[$param_mon-1], $param_year
			;

			$add_param = sprintf
					" %02u.%02u.%04u hh:mm\n" .
					"\n" .
					"ПАРАМЕТРЫ:\n" .
					"\n" .
					"    add           Действие для добавления записей в новый или\n" .
					"                  уже существующий дневник.\n" .
					"\n" .
					"    %02u.%02u.%04u    Дата добавляемой записи.\n" .
					"\n" .
					"    hh:mm         Часы и минуты добавляемой записи (запись будет\n" .
					"                  датирована именно этим временем).\n"
					,
					$param_day, $param_mon, $param_year,
					$param_day, $param_mon, $param_year
			;
		}

		die	"\n" .
			"ОШИБКА!  action_edit(): Дневник на $message ещё не создан.\n" .
			"\n" .
			"Дневник на $message можно создать следующей командой:\n" .
			"\n" .
			"    \$ avg-diary add$add_param" .
			"\n"
		;
	}

	system sprintf ("vim -c 'set expandtab' '%s'", $file);

	avg_diary_file_check_tags $tags, $file;
}

sub action_view {
	my $tag;
	my $calendar_enabled;

	parse_options {
		"-c" => [                0, \$calendar_enabled ],
		"-t" => [ PARSE_OPT_OPTREQ, \$tag              ],
	}, \@_;

	die	"error: unknown parameter '" . $_[0] . "'.\n"
		if $#_ >= 0;

	my $avg_diary = avg_diary::avg_diary->new(
		avg_diary_dir => avg_diary_dir_env
	);

	my $tags = avg_diary::tags::dirtags->new;

	$tags->read_tags_from_dir ( $avg_diary->get_tags_dir );

	die	"error: tag '$tag' not exists.\n"
		if defined $tag and not $tags->tag_ex ( $tag );

	my $dayfiles = $avg_diary->dayfiles_tagged ( $tag );

	my $calendar;

	$calendar = avg_diary::calendar->new ( dayfiles => $dayfiles )
		if $calendar_enabled ;

	open my $fd, " | less -i" or die "error: can't open pipe. $!.\n";

	my $args =
	{
		calendar  => $calendar,
		dayfiles  => $dayfiles,
		fd        => $fd,
		last_date => undef,
		tag       => $tag,
	};

	for my $dayfile ( @{$dayfiles} )
	{
		$args->{dayfile}    = $dayfile;
		$args->{dayfile_rp} = $avg_diary->{avg_diary_dir} . "/" . $dayfile;

		my $file = avg_diary::file->new (
			filename => $args->{dayfile_rp}
		);

		$file->read ( sub
		{
			(my $date, my $time, my $rec, my $tags,
				my $rec_line, my $rec_line_e, my $args) = @_;

			my $calendar = $args->{calendar};
			my $fd       = $args->{fd};
			my $tag      = $args->{tag};

			return AVG_DIARY_FILE_READ
				if defined $tag and not grep /^$tag(\/|$)/, @{$tags};

			if ($args->{last_date} ne $date)
			{
				$date =~ /^ *([0-9]+)\.([0-9]+)\.([0-9]+)/;

				(my $day, my $mon, my $year) = ($1, $2, $3);

				printf { $fd }
					"%s" .
					"\n" .
					"         avg-diary edit %02u.%02u.%04u\n" .
					"\n" .
					"%s"
					,
					$date,
					$day, $mon, $year,
					defined $calendar ? $calendar->print_cal (
						dayfile_name_to_date $args->{dayfile},
					) : ""
				;

				$args->{last_date} = $date;
			}

			print { $fd } $rec;

			return AVG_DIARY_FILE_READ ;
		}, $args);
	}
}

sub avg_diary_dir_env {
	my $avg_diary_dir = $ENV{avg_diary_dir};

	die	"ошибка: не указан путь к дневнику.\n".
		"Укажите правильный путь к дневнику в вашей оболочке\n".
		"\n" .
		"  \$ export avg_diary_dir=<dir>\n" .
		"\n"
		if not defined $avg_diary_dir;

	die	"ошибка: '$avg_diary_dir' не является каталогом.\n".
		"Укажите правильный путь к дневнику в вашей оболочке\n".
		"\n" .
		"  \$ export avg_diary_dir=<dir>\n" .
		"\n"
		if not -d $avg_diary_dir;

	return abs_path $avg_diary_dir;
}

sub avg_diary_file_check_tags {
	(my $tags, my $filename) = @_;

	my $file = avg_diary::file->new ( filename => $filename );

	$file->read ( sub
	{
		(my $date, my $time, my $rec, my $tags,
			my $rec_line, my $rec_line_e, my $args) = @_;

		for my $ct (@{$tags})
		{
			printf	"warning: tag '%s' is not exists.\n",
				$ct if not $args->tag_ex ($ct);
		}
	}, $tags);
}

sub date_check_dmy {
	(my $param_yyyy, my $param_mon, my $param_dd) = @_;

	my $leap_y;
	my $at_ly;

	my $day_min = 1;
	my $day_max;

	$leap_y = ($param_yyyy % 4 == 0) ? 1 : 0;

	if (	($param_mon == 4) or ($param_mon == 6) or ($param_mon == 9) or
		($param_mon == 11) )
	{
		$day_max = 30;
	}
	elsif ($param_mon == 2)
	{
		if ($leap_y)
		{
			$at_ly   = " at leap year";
			$day_max = 29;
		}
		else
		{
			$at_ly   = " at not leap year";
			$day_max = 28;
		}
	}
	elsif ($param_mon < 1 or 12 < $param_mon)
	{
		die "error: incorrect value of month!\n";
	}
	else
	{
		$day_max = 31;
	}

	die "error: month $param_mon$at_ly must have a day between $day_min and $day_max.\n"
		if $param_dd < $day_min or $day_max < $param_dd;
}

sub date_check_hm {
	(my $param_hh, my $param_min) = @_;

	die "error: wrong hours.\n"
		if $param_hh < 0 or 23 < $param_hh;

	die "error: wrong minutes.\n"
		if $param_min < 0 or 59 < $param_min;
}

sub date_correction_year {
	(my $year_ref) = @_;

	my $year = ${$year_ref};

	if (0 <= $year && $year <= 50)
	{
		${$year_ref} = 2000 + $year;
	}
	elsif (51 <= $year && $year <= 99)
	{
		${$year_ref} = 1900 + $year;
	}
}

sub parse_options {
	my $opts_hash = shift;
	my $opts_arr = shift;
	
	while ($#{$opts_arr} >= 0)
	{
		my $cur_opt = ${$opts_arr}[0];

		last if not ($cur_opt =~ /^-/);

		shift @{$opts_arr};

		my $arr1 = ${$opts_hash}{$cur_opt};

		die "error: unknown option '$cur_opt'.\n"
			if not defined $arr1;

		my $flags = \${$arr1}[0];

		die "error: option '$cur_opt' already set.\n"
			if ${$flags} & PARSE_OPT_SET;

		my $ref1 = ${$arr1}[1];

		if ( ${$flags} & PARSE_OPT_OPTREQ )
		{
			die "error: '$cur_opt' require option value.\n"
				if $#{$opts_arr} < 0;

			${$ref1} = shift @{$opts_arr};
		}
		else
		{
			${$ref1} = 1;
		}

		${$flags} |= PARSE_OPT_SET;
	}

	for my $key (keys %{$opts_hash})
	{
		my $arr1 = ${$opts_hash}{$key};
		my $flags = ${$arr1}[0];

		die 	"error: option $key required.\n"
			if not ( $flags & PARSE_OPT_SET )
			and ( $flags & PARSE_OPT_REQ );
	}
}

sub print_usage {
	my $AppName = $0;
	my $AppNameStr = " " x length $AppName;
	printf	"ДЕЛАЙ ТАК:\n".
		"    $AppName add          Добавить запись в дневник. Или завести новый.\n";
}




if (scalar @ARGV == 0)
{
	print_usage;
	exit 1;
}

my $command = shift @ARGV;

my %actions = (
	"add"  => \&action_add,
	"edit" => \&action_edit,
	"view" => \&action_view,
);

my $proc = $actions{$command};

if (not defined $proc)
{
	printf	"ошибка: нет такой команды '%s'.\n".
		"можете запустить программу с любой из этих опций:\n",
		$command;
	my $sep = "";
	for my $a (keys %actions) {
		print $sep, $a;
		$sep = ", ";
	}
	print ".\n";
	exit(1);
}

&{$proc} (@ARGV);

