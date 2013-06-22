#!/usr/bin/env perl

#
# avg-diary - program for text diaries with tags.
# Anton Goncharov, 2013
#

# require v5.6;
use 5.12.0;
use strict;
# use warnings;
use Cwd qw(abs_path);
use File::Spec;
use POSIX qw(strftime);
use List::MoreUtils qw(uniq);

use avg_diary::reader;
use avg_diary::tags;




my $date1;
my $file_new;
my $avg_diary_dir;
my $action_add = 1;
my $action_addrep = 2;
my $action_edit = 3;
my $action_filename = 4;
my $action_tags = 5;
my $action_test = 6;
my $action_tofb2 = 7;
my $action_tofb2_by_tags = 8;
my $action_update = 9;
my $action_view_all = 10;

my $mark_red = "\033[31m";
my $mark_green = "\033[32m";
my $mark_e = "\033[0m";

my $tags_dir;

sub CopyDirStructure($$);
sub FileCheck;
sub FileNewLoadTags;
sub FileProcPrint;
sub FileProcWriteToFile;
sub GenerateFB2;
sub GenerateFB2Dir;
sub TagsClean;
sub TagsCheck;
sub TagsExpand;
sub Test;
sub ToFB2BT;
sub ToFB2Normal;
sub ToFB2BTWriteRecords;
sub ToFB2BTWriteRecordToFile($$$$);
sub Update;
sub UpdateAll;
sub UpdateSaveToFiles;
sub ViewAll;




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
	my $prefix = shift;
	my $prefix2 = "";
	my $is_file_new;
	
	$is_file_new = (-f $file_new) ? 0 : 1;
	
	open DIARY, ">>", "$file_new" or die "$!\n";
	
	if ($is_file_new) {
		my $date_hdr = strftime("%d.%m.%Y, %a", localtime);
		printf DIARY "$date_hdr\n\n";
	}
	
	given ($prefix) {
		when ($action_addrep) {
			$prefix2 = "[ОТЧЁТ]    ";
		}
	}
	
	my $hour_min = strftime("%H:%M", localtime);
	printf DIARY "$hour_min    $prefix2\n\n";
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
	FileNewLoadTags \@tags, $tags_dir;
	open DAY1, "<", $file_new or die "$!";
	while (my $line = <DAY1>) {
		chomp $line;
		given ($line) {
		when (/^ *tags:/) {
			avg_diary::tags::parse_line_with_tags \@tags_in_file, $line, "";
		}}
	}
	TagsCheck \@tags, \@tags_in_file;
}

sub FileNewLoadTags {
	my $tags = shift;
	my $cur_tags_dir = shift;
	my $tags_dir_h;
	my $cur_dir;


	opendir $tags_dir_h, $cur_tags_dir or die "Не получается открыть каталог '$cur_tags_dir'. $!\n";
	while ($cur_dir = readdir $tags_dir_h) {
		if ($cur_dir ne "." && $cur_dir ne "..") {
			my $cur_dir2 = abs_path("$cur_tags_dir/$cur_dir");
			if (-d $cur_dir2) {
				$cur_dir2 =~ /$tags_dir\/*(.*)/;
				push @{$tags}, $1;
				FileNewLoadTags $tags, "$cur_dir2";
			}
		}
	}
	closedir $tags_dir_h;
}

sub FileProcPrint {
	(my $cur_path, my $cur_date, my $cur_record) = @_;

	printf "  %s%ssave to: '%s'%s\n", $cur_record, $mark_green, $cur_path, $mark_e;
}

sub FileProcWriteToFile {
	(my $cur_path, my $cur_date, my $cur_record) = @_;
	my $is_new = (-f $cur_path) ? 0 : 1;
	
	open FILE_DAY, ">>", $cur_path or
			die "не получается открыть файл '$cur_path'. $!.\n";
	
	printf FILE_DAY "%s%s",
		$is_new ? "$cur_date\n\n" : "",
		$cur_record;

	close FILE_DAY;
}

sub GenerateFB2 {
	my $file_fb2;
	my $file_fb2_filename;
#	my $data = { };

	$file_fb2_filename = abs_path($tags_dir."/book.fb2");
	open $file_fb2, ">", $file_fb2_filename or
			die "ошибка: не получается создать файл '$file_fb2_filename'. $!.\n";
	printf $file_fb2
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n".
		"<FictionBook xmlns=\"http://www.gribuser.ru/xml/fictionbook/2.0\" xmlns:l=\"http://www.w3.org/1999/xlink\">\n".
		"<body>\n";
	GenerateFB2Dir $file_fb2, $tags_dir, "", "  ";
	printf $file_fb2
		"</body>\n".
		"</FictionBook>\n";
	close $file_fb2;
}

sub GenerateFB2Dir {
	my $file_fb2 = shift;
	my $cur_dir = shift;
	my $tag_name = shift;
	my $indent = shift;
	my $cur_dir_h;
	my $cur_file;

	opendir $cur_dir_h, $cur_dir or
			die "ошибка: не получается открыть каталог '$cur_dir'. $!.\n";
	while ($cur_file = readdir $cur_dir_h) {
		next if $cur_file eq "." || $cur_file eq "..";

		my $cur_file2 = abs_path($cur_dir."/".$cur_file);
		my $sep = $tag_name eq "" ? "" : "/";
		my $cur_tag = $tag_name.$sep.$cur_file;

		if (-d $cur_file2) {
			printf $file_fb2
				"%s<section>\n", $indent;
			$indent = $indent."  ";
			printf $file_fb2
				"%s<title>\n".
				"%s  <p>%s</p>\n".
				"%s</title>\n",
				$indent,
				$indent,
				$cur_tag,
				$indent;
			printf $file_fb2 "%s<p>section for %s</p>\n", $indent, $cur_tag;
			GenerateFB2Dir $file_fb2, $cur_file2, $cur_tag, $indent;
			$indent =~ s/  $//;
			printf $file_fb2 "%s</section>\n", $indent;
		}
	}
	closedir $cur_dir_h;
}

sub PrintUsage {
	my $AppName = $0;
	my $AppNameStr = " " x length $AppName;
	printf	"ДЕЛАЙ ТАК:\n".
		"    $AppName add          Добавить запись в дневник. Или завести новый.\n".
		"    $AppName addrep       Добавить запись-отчёт в дневник. Или завести новый.\n".
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

sub TagsClean {
	my $cur_tags_dir = shift;
	my $tags_dir_h;
	my $cur_file;

	opendir $tags_dir_h, $cur_tags_dir or
			die "ошибка: не получается открыть каталог с тегами '$cur_tags_dir'. $!.\n";
	while ($cur_file = readdir $tags_dir_h) {
		next if ($cur_file eq "." || $cur_file eq "..");
		my $cur_file2 = abs_path($cur_tags_dir."/".$cur_file);
		if (-d $cur_file2) {
			TagsClean $cur_file2;
		}
		elsif ($cur_file =~ /^day/ || $cur_file =~ /^all/) {
			printf "unlink %s\n", $cur_file2;
			unlink $cur_file2;
		}
	}
	closedir $tags_dir_h;
}

sub TagsCheck {
	(my $tags, my $tags_in_file) = @_;
	my $result = 1;

	for my $ct1 (@{$tags_in_file}) {
		my $finded = 0;
		for my $ct2 (@{$tags}) {
			if ($ct1 eq $ct2) {
				$finded = 1
			}
		}
		if ($finded == 0) {
			$result = 0;
			printf "предупреждение: тег '$ct1' не определён в множестве тегов.\n";
		}
	}
	return $result;
}

sub TagsExpand {
	my $tags = shift;

	for (my $i = 0; $i <= $#{$tags}; ++$i) {
		my @new_tags = split /\//, ${$tags}[$i];
		next if $#new_tags < 1;
		delete $new_tags[$#new_tags];
		my $sep = "";
		my $cur_tag = "";
	L1:	for (my $j = 0; $j <= $#new_tags; ++$j) {
			$cur_tag = $cur_tag.$sep.$new_tags[$j];
			$sep = "/";
			for my $k (@{$tags}) {
				next L1 if $cur_tag eq $k;
			}
			${$tags}[$#{$tags}+1] = $cur_tag;
		}
	}
	@{$tags} = sort @{$tags};
}

sub TagsList {
	my @tags;
	my @tags_in_file;

	CheckCreateTagsPath;
	FileNewLoadTags \@tags, $tags_dir;
	@tags = sort @tags;
	for my $ct (@tags) {
		printf "$ct\n";
	}
}

sub Test {
	my @tags = (
		"tag1/tag11",
		"tag1/tag11/tag111",
		"tag1/tag11/tag111/tag1111/tag11111/tag111111/tag1111111/tag11111111"
	);
	TagsExpand \@tags;

	for my $tag (@tags) {
		printf "%s\n", $tag;
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

sub ToFB2Normal {
	my $filename = shift;
	
	my $reader = avg_diary::reader->new(
			avg_diary_dir => $avg_diary_dir,
			cut_time => 1,
			cut_spaces => 1);
	$reader->first;
	open my $fd, ">", $filename or
			die "ошибка: не получается создать файл '$filename'. $!.\n";
	printf $fd
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n".
		"<FictionBook xmlns=\"http://www.gribuser.ru/xml/fictionbook/2.0\" xmlns:l=\"http://www.w3.org/1999/xlink\">\n".
		"<body>\n";
	my $date_last;
	while (my $rec = $reader->fetch) {
		my $date = $rec->{date};
		if ($date ne $date_last) {
			printf	$fd
				"</section>\n" if $date_last ne "";
			printf	$fd
				"<section>\n".
				"<title>\n".
				"  <p>%s</p>\n".
				"</title>\n", $date;
			$date_last = $date;
		}

		my $time = $rec->{time};
		my $record = $rec->{record};
		$record =~ s/&/&amp;/g;
		$record =~ s/</&lt;/g;
		$record =~ s/>/&gt;/g;
		$record =~ s/$/<\/v>/mg;
		$record =~ s/^/  <v>/mg;

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
	}
	printf $fd
		"</section>\n".
		"</body>\n".
		"</FictionBook>\n";
	close $fd;
}

sub Update {
	my @tags;
	my $diary_dir_h;
	my $cur_file;
	my @files;

	CheckCreateTagsPath;
	TagsClean $tags_dir;
	FileNewLoadTags \@tags, $tags_dir;
	opendir $diary_dir_h, $avg_diary_dir or die "Не получается открыть каталог '$avg_diary_dir'. $!.\n";
	while ($cur_file = readdir $diary_dir_h) {
		if ($cur_file =~ /^day_/) {
			push @files, $cur_file;
		}
	}
	closedir $diary_dir_h;

	my $file_proc = \&FileProcWriteToFile;

	my $state_init = 1;
	my $state_date = 2;
	my $state_rec = 3;

	my $state = $state_init;

	@files = sort @files;
	for my $file1 (@files) {
		my $file2 = abs_path(${avg_diary_dir}."/".${file1});
		my $cur_date;
		my $cur_record;
		my @tags_in_record;

		open DAY1, "<", $file2 or die "Не получается открыть файл '$file2'. $!.\n";
		my $line_num = 1;
		while (my $line = <DAY1>) {
			given ($state) {
			when ($state_init) {
				given ($line) {
				when (/^[0-9]{2}\.[0-9]{2}\.[0-9]+/) {
					chomp $line;
					$cur_date = $line;
					$state = $state_date;
				}
				when (/^$/) {
				}
				default {
					printf "%s:%u: нарушение синтаксиса.\n", $file2, $line_num;
					exit 1;
				}
				}
			}
			when ($state_date) {
				given ($line) {
				when (/^[0-9]{2}\.[0-9]{2}\.[0-9]+/) {
					chomp $line;
					$cur_date = $line;
				}
				when (/^[0-9]{2}:[0-9]{2}/) {
					$cur_record = $line;
					$state = $state_rec;
				}
				when (/^$/) {
				}
				default {
					printf "%s:%u: нарушение синтаксиса.\n", $file2, $line_num;
					exit 1;
				}
				}
			}
			when ($state_rec) {
				given ($line) {
				when (/^[0-9]{2}\.[0-9]{2}\.[0-9]+/) {
					UpdateSaveToFiles \@tags, \@tags_in_record, $cur_date, $cur_record, $file_proc;
					@tags_in_record = ();
					chomp $line;
					$cur_date = $line;
					$state = $state_date;
				}
				when (/^[0-9]{2}:[0-9]{2}/) {
					UpdateSaveToFiles \@tags, \@tags_in_record, $cur_date, $cur_record, $file_proc;
					@tags_in_record = ();
					$cur_record = $line;
				}
				when (/^ +tags:/) {
					avg_diary::tags::parse_line_with_tags \@tags_in_record, $line, "$file2:$line_num";
					$cur_record = $cur_record.$line;
				}
				default {
					$cur_record = $cur_record.$line;
				}
				}
			}
			}
			++$line_num;
		}
		close DAY1;
		if ($state == $state_rec) {
			UpdateSaveToFiles \@tags, \@tags_in_record, $cur_date, $cur_record, $file_proc;
			$state = $state_init;
		}
	}
	UpdateAll $tags_dir;
	GenerateFB2;
}

sub UpdateAll {
	my $cur_tags_dir = shift;
	my $tags_dir_h;
	my $cur_file;

	opendir $tags_dir_h, $cur_tags_dir or
			die "ошибка: не получается открыть каталог с тегами '$cur_tags_dir'. $!.\n";
	my $cur_all_filename = abs_path($cur_tags_dir."/all.txt");
	open my $file_all, ">>", $cur_all_filename or
			die "ошибка: не получается открыть файл '$cur_all_filename'. $!.\n";
	while ($cur_file = readdir $tags_dir_h) {
		next if ($cur_file eq "." || $cur_file eq "..");
		my $cur_file2 = abs_path($cur_tags_dir."/".$cur_file);
		if (-d $cur_file2) {
			UpdateAll $cur_file2;
		}
		elsif ($cur_file =~ /^day_/) {
			open FILE_DAY, "<", $cur_file2 or
					die "ошибка: не получается открыть файл '$cur_file2'. $!.\n";
			my $line;
			while ($line = <FILE_DAY>) {
				printf $file_all "%s", $line;
			}
			close FILE_DAY;
		}
	}
	closedir $tags_dir_h;
	close $file_all;
}

sub UpdateSaveToFiles {
	(my $tags, my $tags_in_record, my $cur_date, my $cur_record, my $file_proc) = @_;

	if ($cur_date eq "") {
		printf "date must be not empty.\n";
		exit(1);
	}

	if (!TagsCheck $tags, $tags_in_record) {
		chomp $cur_date;
		printf "exit. date: %s\n", $cur_date;
		exit(1);
	}

	TagsExpand $tags_in_record;

	$cur_date =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/;
	my $filename1 = "day_$3_$2_$1.txt";

	if (scalar @{$tags_in_record} == 0) {
		my $cur_path = abs_path($avg_diary_dir."/tags/".$filename1);
		&{$file_proc}($cur_path, $cur_date, $cur_record);
	}
	else {
		for my $cur_tag (@{$tags_in_record}) {
			my $cur_path = abs_path($avg_diary_dir."/tags/".$cur_tag."/".$filename1);
			&{$file_proc}($cur_path, $cur_date, $cur_record);
		}
	}
}

sub ViewAll {
	exec "bash", "-c", sprintf("cat \$(ls %s/day_*) | less", $avg_diary_dir);
}




if (scalar @ARGV == 0) {
	PrintUsage;
	exit 1;
}




my $action;
my $command;
my $file_name = "";

while (($command = shift @ARGV) && $command =~ /^--/) {
	given ($command) {
		when (/^--avg-diary-dir=(.*)/) {
			$avg_diary_dir = abs_path $1;
		}
		when (/^--file=(.*)/) {
			$file_name = $1;
		}
		default {
			printf STDERR "ошибка: неизвестный параметр '$command'.\n";
			PrintUsage;
			exit(1);
		}
	}
}

given ($command) {
	when (/^$/) {
		printf STDERR "ошибка: не указано действие.\n";
		PrintUsage;
		exit(1);
	}
	when (/^add$/)			{ $action = $action_add; }
	when (/^addrep$/)		{ $action = $action_addrep; }
	when (/^edit$/)			{ $action = $action_edit; }
	when (/^filename$/)		{ $action = $action_filename; }
	when (/^tags$/)			{ $action = $action_tags; }
	when (/^test$/)			{ $action = $action_test; }
	when (/^tofb2$/)		{ $action = $action_tofb2; }
	when (/^tofb2-by-tags$/)	{ $action = $action_tofb2_by_tags; }
	when (/^update$/)		{ $action = $action_update; }
	when (/^view-?all$/)		{ $action = $action_view_all; }
	default {
		printf STDERR "ошибка: неверный параметр: '$command'.\n";
		PrintUsage;
		exit(1);
	}
}

AvgDiaryDirEnv;

$date1 = strftime("%Y_%m_%d", localtime);
if ($file_name eq "") {
	$file_new = abs_path($avg_diary_dir."/day_".$date1);
}
else {
	$file_new = abs_path($avg_diary_dir."/".$file_name);
}

my $action_tags_action;

given ($action) {
	when ([	$action_add,
		$action_addrep ])  { FileAddEntry $action; }
	when ($action_edit)        { FileEditEntry; }
	when ($action_filename) {
		printf "$file_new\n";
	}
	when ($action_tags) {
		$action_tags_action = shift @ARGV;
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
	when ($action_test) {
		Test;
	}
	when ($action_tofb2) {
		if (scalar @ARGV != 1) {
			printf "ошибка: нужно указать путь к fb2-книге.\n";
			PrintUsage;
			exit(1);
		}
		my $fb2_arg = shift @ARGV;
		ToFB2Normal $fb2_arg;
	}
	when ($action_tofb2_by_tags) {
		if (scalar @ARGV != 1) {
			printf "ошибка: нужно указать путь к fb2-книге.\n";
			PrintUsage;
			exit(1);
		}
		my $fb2_arg = shift @ARGV;
		ToFB2BT $fb2_arg;
	}
	when ($action_update) {
		Update;
	}
	when ($action_view_all) {
		ViewAll;
	}
	default {
		printf STDERR "ошибка: неизвестный action: '$action'.\n";
		PrintUsage;
		exit(1);
	}
}
