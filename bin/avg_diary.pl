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
sub CopyDirStructure($$);
sub FileCheck;
sub parse_options;
sub ToFB2BT;
sub ToFB2BTWriteRecords;
sub ToFB2BTWriteRecordToFile($$$$);




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

sub CopyDirStructure($$) {
	(my $src, my $dst) = @_;

	opendir my $src_h, $src or die sprintf("ошибка: не получается открыть исходный каталог '%s'.\n", $src);

	while (my $src2 = readdir $src_h) {
		next if ($src2 eq ".") or ($src2 eq "..");
		my $src3 = abs_path($src."/".$src2);
		next if not -d $src3;
		my $dst3 = abs_path($dst."/".$src2);
		mkdir $dst3 or die sprintf(
				"ошибка: не получается создать каталог назначения '%s'.\n",
				$dst3);
		CopyDirStructure $src3, $dst3;
	}

	closedir $src_h;
}

sub FileAddEntry {
	my $is_file_new;
	
	$is_file_new = (-f $file_new) ? 0 : 1;
	
	open DIARY, ">>", "$file_new" or die "$!\n";
	
	if ($is_file_new) {
		my $date_hdr = strftime("%d.%m.%Y, %a", localtime);
		printf DIARY "$date_hdr\n\n";
	}
	
	my $hour_min = strftime("%H:%M", localtime);
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

sub ToFB2BT {
	my $fb2_filename = shift;

	my $tmp_dir = "/tmp/diary-fb2.tmp";
	system "rm -rf $tmp_dir";
	mkdir $tmp_dir or die sprintf(
			"ошибка: не получается создать каталог '%s'. %s.\n",
			$tmp_dir, $!);
	CheckCreateTagsPath $tags_dir;
	CopyDirStructure $tags_dir, $tmp_dir;
	
	my $reader = avg_diary::reader->new(
			avg_diary_dir => $avg_diary_dir,
			cut_time => 1,
			cut_spaces => 1);
	$reader->first;
	while (my $rec = $reader->fetch) {
		my $tags = $rec->{tags};
		my $date = $rec->{date};
		$date =~ /0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)/;
		my $day_filename = sprintf "day_%04u_%02u_%02u.html", $3, $2, $1;
		if ($#{$tags} >= 0) {
			for my $cur_tag (@{$tags}) {
				my $filename = abs_path(
						$tmp_dir."/".$cur_tag."/".$day_filename);
				ToFB2BTWriteRecordToFile
						$filename,
						$rec->{date},
						$rec->{time},
						$rec->{record};
			}
		}
		else {
			my $filename = abs_path($tmp_dir."/".$day_filename);
			ToFB2BTWriteRecordToFile
					$filename,
					$rec->{date},
					$rec->{time},
					$rec->{record};
		}
	}

	open my $fb2_file, ">", $fb2_filename or die sprintf(
			"ошибка: не получается открыть файл '%s'. %s.\n",
			$fb2_filename, $!);
	printf $fb2_file
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n".
		"<FictionBook xmlns=\"http://www.gribuser.ru/xml/fictionbook/2.0\" xmlns:l=\"http://www.w3.org/1999/xlink\">\n".
		"<body>\n";
	ToFB2BTWriteRecords $fb2_file, $tmp_dir, "";
	printf $fb2_file
		"</body>\n".
		"</FictionBook>\n";
	close $fb2_file;
	system "rm -rf $tmp_dir";
}

sub ToFB2BTWriteRecords {
	(my $fb2_file, my $dir, my $tag) = @_;

	my @dirs;
	my @files;

	opendir my $dir_h, $dir or die sprintf(
			"ошибка: не получается открыть каталог '%s'. %s.\n",
			$dir, $!);
	while (my $cur_file = readdir $dir_h) {
		next if $cur_file eq "." or $cur_file eq "..";
		my $cur_file2 = abs_path($dir."/".$cur_file);
		if (-d $cur_file2) {
			push @dirs, $cur_file;
		}
		elsif (-f $cur_file2 && $cur_file =~ /^day_/) {
			push @files, $cur_file;
		}
	}
	closedir $dir_h;

	for my $cur_dir (sort @dirs) {
		my $cur_dir2 = abs_path($dir."/".$cur_dir);
		my $cur_tag = ($tag eq "") ? $cur_dir : $tag."/".$cur_dir;
		ToFB2BTWriteRecords $fb2_file, $cur_dir2, $cur_tag;
	}

	my $tag_text;

	if ($tag eq "") {
		$tag_text = "без тега";
	}
	else {
		$tag_text = $tag;
		$tag_text =~ s/&/&amp;/g;
		$tag_text =~ s/</&lt;/g;
		$tag_text =~ s/>/&gt;/g;
	}

	printf $fb2_file
		"<section>\n".
		"<title>\n".
		"  <p>%s</p>\n".
		"</title>\n", $tag_text;
	for my $cur_file (sort @files) {
		my $cur_file2 = abs_path($dir."/".$cur_file);
		open my $fd, "<", $cur_file2 or
				die sprintf ("ошибка: не получается открыть файл '%s'. %s.\n",
				$cur_file2, $!);
		while (my $line = <$fd>) { print $fb2_file "  ",$line; }
		close $fd;
	}
	printf $fb2_file "</section>\n";
}

sub ToFB2BTWriteRecordToFile($$$$) {
	(my $filename, my $date, my $time, my $record) = @_;
	my $new_file = (-f $filename) ? 0 : 1;

	$record =~ s/&/&amp;/g;
	$record =~ s/</&lt;/g;
	$record =~ s/>/&gt;/g;
	$record =~ s/$/<\/v>/mg;
	$record =~ s/^/  <v>/mg;

	open my $fd, ">>", $filename or die
		sprintf("ошибка: не получается открыть файл '%s'. %s.\n", $filename, $!);
	printf $fd
		"<p>\n".
		"  <strong>%s</strong>\n".
		"</p>\n",
		$date if $new_file;
	printf $fd
		"<p>\n".
		"  <strong>%s</strong>\n".
		"</p>\n".
		"<poem>\n".
		"<stanza>\n".
		"%s\n".
		"</stanza>\n".
		"</poem>\n",
		$time, $record;
	close $fd;
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
	FileAddEntry;
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
	ToFB2BT $fb2_arg;
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

