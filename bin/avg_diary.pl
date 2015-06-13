#!/usr/bin/env perl

#
# avg-diary - program for text diaries with tags.
# Anton Goncharov, 2013-2015
#

BEGIN {
	my $debug = 0;
	@INC = ("./lib", @INC) if $debug == 1;
}

use 5.12.0;
use strict;
use Cwd qw(abs_path);
use File::Basename;
use File::Spec;
use POSIX qw(strftime);
use List::MoreUtils qw(uniq);

use avg_diary::fb2::bytags;
use avg_diary::fb2::normal;
use avg_diary::reader;
use avg_diary::tags;




my $date1;
my $file_new;
my $avg_diary_dir;

my $mark_red = "\033[31m";
my $mark_green = "\033[32m";
my $mark_e = "\033[0m";

my $tags_dir;

sub action_add;
sub action_edit;
sub action_filename;
sub action_tags;
sub action_tofb2;
sub action_tofb2_by_tags;
sub action_view;
sub action_view_all;
sub FileCheck;
sub parse_options;




sub AvgDiaryDirEnv {
	$avg_diary_dir = $ENV{avg_diary_dir};

	die	"ошибка: не указан путь к дневнику.\n".
		"Укажите правильный путь к дневнику в вашей оболочке\n".
		"export avg_diary_dir=<dir>\n"
		if $avg_diary_dir eq "";

	die	"ошибка: '$avg_diary_dir' не является каталогом.\n".
		"Укажите правильный путь к дневнику в вашей оболочке\n".
		"export avg_diary_dir=<dir>\n"
		if not -d $avg_diary_dir;

	$avg_diary_dir = abs_path $avg_diary_dir;
}

sub CheckCreateTagsPath {
	$tags_dir = abs_path($avg_diary_dir."/tags");
	if (! -d $tags_dir) {
		mkdir "$tags_dir" or die "Не получается создать каталог '$tags_dir'. $!\n";
	}
}

sub FileAddEntry {
	(my %cnf) = @_;

	my $uptime = delete $cnf{uptime};
	$uptime = 0 unless defined $uptime;

	my $is_file_new;
	
	$is_file_new = (-f $file_new) ? 0 : 1;
	
	open DIARY, ">>", "$file_new" or die "$!\n";
	
	if ($is_file_new) {
		my $date_hdr = strftime("%d.%m.%Y, %a", localtime);
		printf DIARY "$date_hdr\n\n";
	}
	
	my $hour_min;

	if ($uptime == 0) {
		$hour_min = strftime("%H:%M", localtime);
	}
	else {
		$hour_min = `uptime -s`;
		$hour_min =~ /0*([0-9]+)-0*([0-9]+)-0*([0-9]+) *0*([0-9]+):0*([0-9]+):0*([0-9]+)/;
		$hour_min = sprintf "%02d:%02d", $4, $5;
	}

	printf DIARY "$hour_min    \n\n";
	close DIARY;
	
	system("vim -c 'set expandtab' -c 'normal GkA' $file_new");
	
	FileCheck;
}

sub FileEditEntry {
	my $is_file_new;
	
	$is_file_new = (-f $file_new) ? 0 : 1;
	
	if ($is_file_new) {
		printf STDERR
			"ошибка: сегодняшний дневник ещё не создан.\n".
			"можно создать дневник командой:\n".
			"\n".
			"    avg-diary add\n".
			"\n";
		exit(1);
	}
	
	system("vim -c 'set expandtab' -c 'normal GkA' $file_new");
	
	FileCheck;
}

sub FileCheck {
	my @tags;
	my @tags_in_file;

	CheckCreateTagsPath;
	tags_load_from_file \@tags, $tags_dir;
	open DAY1, "<", $file_new or die "$!";
	while (my $line = <DAY1>) {
		chomp $line;
		given ($line) {
		when (/^ *tags:/) {
			parse_line_with_tags \@tags_in_file, $line, "";
		}}
	}
	tags_check \@tags, \@tags_in_file;
}

sub parse_options {
	my $opts_hash = shift;
	my $opts_arr = shift;
	
	while ($#{$opts_arr} >= 0) {
		my $cur_opt = ${$opts_arr}[0];
		last if not ($cur_opt =~ /^-/);
		shift @{$opts_arr};
		my $arr1 = ${$opts_hash}{$cur_opt};
		die "error: unknown option '$cur_opt'.\n"
				if not defined $arr1;
		die "error: option '$cur_opt' already set.\n"
				if ${$arr1}[0] == 2;
		my $ref1 = ${$arr1}[1];
		if (ref($ref1) eq "SCALAR") {
			die "error: '$cur_opt' require option value.\n"
					if $#{$opts_arr} < 0;
			${$ref1} = shift @{$opts_arr};
		}
		${$arr1}[0] = 2;
	}

	for my $key (keys %{$opts_hash}) {
		my $arr1 = ${$opts_hash}{$key};
		die "error: option $key required.\n" if ${$arr1}[0] == 1;
	}
}

sub PrintUsage {
	my $AppName = $0;
	my $AppNameStr = " " x length $AppName;
	printf	"ДЕЛАЙ ТАК:\n".
		"    $AppName add          Добавить запись в дневник. Или завести новый.\n".
		"    $AppName edit         Редактировать сегодняшнюю запись.\n".
		"    $AppName help         Вывести справку.\n".
		"    $AppName tags list    Вывести список доступных тегов.\n".
		"    $AppName filename     Вывести имя текущего файла.\n".
		"    $AppName tofb2 <filename>\n".
		$AppNameStr."                  Сохранить дневник в формате электронной книги.\n".
		$AppNameStr."                  Сохранить записи в том порядке в котором они следуют\n".
		$AppNameStr."                  в дневнике.\n".
		"    $AppName tofb2-by-tags <filename>\n".
		$AppNameStr."                  Сохранить дневник в формате электронной книги.\n".
		"    $AppName view-all     Читать весь дневник.\n";
}

sub TagsAdd {
	my $command;
	
	while ($command = shift @ARGV) {
		printf "tag: $command\n";
	}
}

sub TagsList {
	my @tags;
	my @tags_in_file;

	CheckCreateTagsPath;
	tags_load_from_file \@tags, $tags_dir;
	for my $ct (@tags) {
		printf "$ct\n";
	}
}




if (scalar @ARGV == 0) {
	PrintUsage;
	exit 1;
}

my $command = shift @ARGV;
my $file_name = "";

while ($command =~ /^--/) {
	given ($command) {
		when (/^--avg-diary-dir=(.*)/) {
			$avg_diary_dir = abs_path $1;
		}
		when (/^--file=(.*)/) {
			$file_name = $1;
		}
		default {
			printf STDERR "ошибка: неизвестная опция '$command'.\n";
			PrintUsage;
			exit(1);
		}
	}
	$command = shift @ARGV;
	if (not defined $command) {
		printf STDERR "ошибка: не указана команда.\n";
		PrintUsage;
		exit(1);
	}
}

if ($command =~ /^-/) {
	printf STDERR "ошибка: неизвестная опция: '%s'.\n", $command;
	PrintUsage;
	exit(1);
}

my %actions = (
	"add"		=> \&action_add,
	"edit"		=> \&action_edit,
	"filename"	=> \&action_filename,
	"tags"		=> \&action_tags,
	"tofb2"		=> \&action_tofb2,
	"tofb2-by-tags"	=> \&action_tofb2_by_tags,
	"view"		=> \&action_view,
	"view-all"	=> \&action_view_all,
	"viewall"	=> \&action_view_all
);

AvgDiaryDirEnv;

$date1 = strftime("%Y_%m_%d", localtime);
if ($file_name eq "") {
	$file_new = abs_path($avg_diary_dir."/day_".$date1);
}
else {
	$file_new = abs_path($avg_diary_dir."/".$file_name);
}

sub action_add {
	my $arg = shift @ARGV;
	my %cnf;

	if (defined $arg) {
		if ($arg eq "--uptime") {
			$cnf{uptime} = 1;
		}
		else {
			print "error: unknown for 'add' option '$arg'.\n";
			exit(1);
		}
	}

	FileAddEntry %cnf;
}

sub action_edit {
	FileEditEntry;
}

sub action_filename {
	print "$file_new\n";
}

sub action_tags {
	my $action_tags_action = shift @ARGV;
	given ($action_tags_action) {
	when (/^add$/) {
		TagsAdd;
	}
	when (/^list$/) {
		TagsList;
	}
	when (/^$/) {
		printf STDERR "ошибка: не указан параметр для действия 'tags'.\n";
		PrintUsage;
	}
	default {
		printf STDERR	"ошибка: указан плохой параметр ('$action_tags_action')\n".
				"        для действия 'tags'\n";
		PrintUsage;
	}}
}

sub action_tofb2 {
	if (scalar @ARGV != 1) {
		printf "ошибка: нужно указать путь к fb2-книге.\n";
		PrintUsage;
		exit(1);
	}
	my $fb2_arg = shift @ARGV;
	fb2_normal $avg_diary_dir, $fb2_arg;
}

sub action_tofb2_by_tags {
	if (scalar @ARGV != 1) {
		printf "ошибка: нужно указать путь к fb2-книге.\n";
		PrintUsage;
		exit(1);
	}
	my $fb2_arg = shift @ARGV;
	fb2_by_tags $avg_diary_dir, $fb2_arg;
}

sub action_view {
	my $tag_name = "";

	parse_options { "-t" => [ 0, \$tag_name ] }, \@ARGV;

	$tag_name =~ s/^[ \t\/]*//g;
	$tag_name =~ s/[ \t\/]*$//g;

	my $reader = avg_diary::reader->new(
			avg_diary_dir => $avg_diary_dir,
			cut_time => 0,
			cut_spaces => 0);
	$reader->first;

	my $date_last;
	open my $fd, " | less -i" or die "can't open pipe. $!.\n";

	if ($tag_name eq "") {
		printf $fd "%sAll records.%s\n\n", $mark_green, $mark_e;
	}
	else {
		printf $fd "%sRecords with tag '%s'.%s\n\n", $mark_green, $tag_name, $mark_e;
	}

	while (my $rec = $reader->fetch) {
		my $tags = $rec->{tags};

		if ($tag_name ne "") {
			next if not grep /^$tag_name(\/|$)/, @{$tags};
		}

		my $date = $rec->{date};
		if ($date ne $date_last) {
			my $cmd = sprintf "avg-diary --file=%s edit", basename($rec->{cur_filename});
			printf $fd "%s\n\n         %s\n\n", $date, $cmd;
			$date_last = $date;
		}

		my $time = $rec->{time};
		my $record = $rec->{record};

		printf $fd "%s", $record;
	}

	close $fd;
}

sub action_view_all {
	exec "bash", "-c", sprintf("cat \$(ls %s/day_*) | less -i", $avg_diary_dir);
}


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

