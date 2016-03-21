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
use Time::Local;

use avg_diary::add;
use avg_diary::file;




sub action_add;
sub avg_diary_add;
sub avg_diary_dir_env;
sub print_usage;




my $mark_red = "\033[31m";
my $mark_green = "\033[32m";
my $mark_e = "\033[0m";




sub action_add {
	my $param_uptime;
	my $param_dd;
	my $param_mon;
	my $param_yyyy;
	my $param_hh;
	my $param_min;

	my %cnf;

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

	#
	# today is 17.03.2016 10:49.
	#
	#   avg-diary add --uptime
	#   avg-diary add 01.02.2011       -- please, specify a datetime.
	#   avg-diary add 01.02.2011 10:00 -- ok.
	#
	# alternative:
	#
	#   avg-diary add 01.02.2011       -- empty record?
	#

	if (defined $param_dd)
	{
		die "error: empty times is not supported.\n"
				if not defined $param_hh;

		if (0 <= $param_yyyy && $param_yyyy <= 50)
		{
			$param_yyyy += 2000;
		}
		elsif (51 <= $param_yyyy && $param_yyyy <= 99)
		{
			$param_yyyy += 1900;
		}
	}
	elsif (not defined $param_uptime)
	{
		(	my $now_sec,  my $now_min,  my $now_hour,
			my $now_mday, my $now_mon,  my $now_year,
			my $now_wday, my $now_yday, my $now_isdst) = localtime;

		$now_mon  += 1;
		$now_year += 1900;

		$param_dd   = $now_mday;
		$param_mon  = $now_mon;
		$param_yyyy = $now_year;

		if (not defined $param_hh)
		{
			$param_hh    = $now_hour;
			$param_min   = $now_min;
		}

	}

	if (defined $param_uptime)
	{
		$cnf{uptime} = 1;
	}
	else
	{
		my $leap_y;
		my $at_ly;

		my $day_min = 1;
		my $day_max;

		$leap_y = ($param_yyyy % 4 == 0) ? 1 : 0;

		if ($param_mon < 1 or 12 < $param_mon)
		{
			die "error: incorrect value of month!\n";
		}

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
		else
		{
			$day_max = 31;
		}

		die "error: month $param_mon$at_ly must have a day between $day_min and $day_max.\n"
			if $param_dd < $day_min or $day_max < $param_dd;

		die "error: wrong hours.\n"
			if $param_hh < 0 or 23 < $param_hh;

		die "error: wrong minutes.\n"
			if $param_min < 0 or 59 < $param_min;

		$cnf{date} = [
			$param_dd,
			$param_mon,
			$param_yyyy,
			$param_hh,
			$param_min,
		];
	}

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
	"add" => \&action_add,
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

