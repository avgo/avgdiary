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




my $mark_red = "\033[31m";
my $mark_green = "\033[32m";
my $mark_e = "\033[0m";




sub avg_diary_dir_env {
	my $avg_diary_dir = $ENV{avg_diary_dir};

	die	"ошибка: не указан путь к дневнику.\n".
		"Укажите правильный путь к дневнику в вашей оболочке\n".
		"export avg_diary_dir=<dir>\n"
		if not defined $avg_diary_dir;

	die	"ошибка: '$avg_diary_dir' не является каталогом.\n".
		"Укажите правильный путь к дневнику в вашей оболочке\n".
		"export avg_diary_dir=<dir>\n"
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

my %actions = ( );




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

&{$proc};

