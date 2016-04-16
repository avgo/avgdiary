#!/usr/bin/env perl

#
# avg-diary - program for text diaries with tags.
# Anton Goncharov, 2013 - 2016.
#

BEGIN {
	my $debug = 1;
	@INC = ("./lib", @INC) if $debug == 1;
}

use strict;

use Cwd qw(abs_path);

use avg_diary::add;
use avg_diary::avg_diary;
use avg_diary::file;




sub action_add;
sub avg_diary_add;
sub avg_diary_dir_env;
sub date_check_dmy;
sub date_check_hm;
sub date_correction_year;
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

	if (defined $param_dd)
	{
		#   avg-diary add 01.02.2011       -- error! Maybe add an empty record?

		die "error: empty times is not supported.\n"
				if not defined $param_hh;

		#   avg-diary add 01.02.2011 11:01

		date_correction_year \$param_yyyy;
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

		(	my $now_sec,  my $now_min,  my $now_hour,
			my $now_mday, my $now_mon,  my $now_year,
			my $now_wday, my $now_yday, my $now_isdst) = localtime;

		$now_mon  += 1;
		$now_year += 1900;

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

	my %cnf =
	(
		date => [
			$param_dd,
			$param_mon,
			$param_yyyy,
			$param_hh,
			$param_min,
		],
		file => $avg_diary->day_filename(
			$param_yyyy, $param_mon, $param_dd
		),
	);

	avg_diary_add %cnf;
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

sub action_edit {
	my $avg_diary = avg_diary::avg_diary->new(
		avg_diary_dir => avg_diary_dir_env
	);

	(	my $now_sec,  my $now_min,  my $now_hour,
		my $now_mday, my $now_mon,  my $now_year,
		my $now_wday, my $now_yday, my $now_isdst) = localtime;

	$now_mon  += 1;
	$now_year += 1900;

	my $day_filename = $avg_diary->day_filename(
		$now_year, $now_mon, $now_mday
	);

	die	"ошибка action_edit(): Дневник на сегодня ещё не создан.\n" .
		"Дневник на сегодня можно создать следующей командой:\n" .
		"\n" .
		"    avg-diary add\n" .
		"\n"

		if not -f $day_filename;

	system sprintf ("vim -c 'set expandtab' '%s'", $day_filename);
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

sub print_usage {
	my $AppName = $0;
	my $AppNameStr = " " x length $AppName;
	printf	"ДЕЛАЙ ТАК:\n".
		"    $AppName add          Добавить запись в дневник. Или завести новый.\n";
}




if (scalar @ARGV == 0) {
	print_usage;
	exit 1;
}

my $command = shift @ARGV;

my %actions = (
	"add"  => \&action_add,
	"edit" => \&action_edit,
);

my $proc = $actions{$command};

if (not defined $proc) {
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

