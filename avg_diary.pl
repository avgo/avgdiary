#!/usr/bin/env perl

# require v5.6;
use 5.12.0;
use strict;
# use warnings;
use Cwd qw(abs_path);
use File::Spec;
use POSIX qw(strftime);




my $date1;
my $file_new;
my $avg_diary_dir;
my $action_add = 1;
my $action_addrep = 2;
my $action_edit = 3;
my $action_filename = 4;
my $action_tags = 5;
my $tags_dir;

sub FileCheck;
sub FileNewLoadTags;




sub AvgDiaryDirCheck {
	if ($avg_diary_dir eq "") {
		printf STDERR "ошибка: не указан путь к дневнику.\n".
		              "Укажите правильный путь к дневнику в вашей оболочке\n".
			      "export avg_diary_dir=<dir>\n";
		exit(1);
	}
	
	if (! -d $avg_diary_dir) {
		printf STDERR "ошибка: '$avg_diary_dir' не является каталогом.\n".
		              "Укажите правильный путь к дневнику в вашей оболочке\n".
			      "export avg_diary_dir=<dir>\n";
		exit(1);
	}
}

sub AvgDiaryDirEnv {
	return if $avg_diary_dir ne "";
	$avg_diary_dir = $ENV{avg_diary_dir};
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

	$tags_dir = abs_path($avg_diary_dir."/tags");
	if (! -d $tags_dir) {
		mkdir "$tags_dir" or die "Не получается создать каталог '$tags_dir'. $!\n";
	}
	FileNewLoadTags \@tags, $tags_dir;
	open DAY1, "<", $file_new or die "$!";
	while (my $line = <DAY1>) {
		chomp $line;
		given ($line) {
		when (/^ *tags:/) {
			$line =~ s/^ *tags: *//g;
			while ($line) {
				if ( ! ($line =~ s/^\[([^\]]*)\][, ]*//)) {
					printf "некорректное определение тега: $line\n";
					$line = "";
				}
				elsif ($1 eq "") {
					printf "пустой тег\n";
				}
				else {
					push @tags_in_file, $1
				}
			}
		}
		}
	}
	for my $ct1 (@tags_in_file) {
		my $finded = 0;
		for my $ct2 (@tags) {
			if ($ct1 eq $ct2) {
				$finded = 1
			}
		}
		if ($finded == 0) {
			printf "предупреждение: тег '$ct1' не определён в множестве тегов.\n";
		}
	}
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

sub PrintUsage {
	my $AppName = $0;
	printf 
		"ДЕЛАЙ ТАК:\n".
		"    $AppName add         Добавить запись в дневник. Или завести новый.\n".
		"    $AppName addrep      Добавить запись-отчёт в дневник. Или завести новый.\n".
		"    $AppName edit        Редактировать сегодняшнюю запись.\n".
		"    $AppName help        Вывести справку.\n".
		"    $AppName tags list   Вывести список доступных тегов.\n".
		"    $AppName filename    Вывести имя текущего файла.\n".
		"    $AppName view-all    Читать весь дневник.\n";
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

	$tags_dir = abs_path($avg_diary_dir."/tags");
	if (! -d $tags_dir) {
		mkdir "$tags_dir" or die "Не получается создать каталог '$tags_dir'. $!\n";
	}
	FileNewLoadTags \@tags, $tags_dir;
	@tags = sort @tags;
	for my $ct (@tags) {
		printf "$ct\n";
	}
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
			$avg_diary_dir = $1;
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
	when (/^add$/)		{ $action = $action_add; }
	when (/^addrep$/)	{ $action = $action_addrep; }
	when (/^edit$/)		{ $action = $action_edit; }
	when (/^filename$/)	{ $action = $action_filename; }
	when (/^tags$/)		{ $action = $action_tags; }
	default {
		printf STDERR "ошибка: неверный параметр: '$command'.\n";
		PrintUsage;
		exit(1);
	}
}

AvgDiaryDirEnv;
AvgDiaryDirCheck;

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
	default {
		printf STDERR "ошибка: неизвестный action: '$action'.\n";
		PrintUsage;
		exit(1);
	}
}
