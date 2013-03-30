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




sub AvgDiaryDirCheck {
	$avg_diary_dir = $ENV{avg_diary_dir};
	
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
	
	system("vim -c 'set expandtab' -c 'normal GkA' $file_new");
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
}

sub PrintUsage {
	my $AppName = $0;
	printf 
		"ДЕЛАЙ ТАК:\n".
		"    $AppName add         Добавить запись в дневник. Или завести новый.\n".
		"    $AppName addrep      Добавить запись-отчёт в дневник. Или завести новый.\n".
		"    $AppName edit        Редактировать сегодняшнюю запись.\n".
		"    $AppName help        Вывести справку.\n".
		"    $AppName filename    Вывести имя текущего файла.\n".
		"    $AppName view-all    Читать весь дневник.\n";
}




if (scalar @ARGV != 1) {
	PrintUsage;
	exit 1;
}




my $action;
my $command = $ARGV[0];

given ($command) {
	when (/^add$/)    { $action = $action_add; }
	when (/^addrep$/) { $action = $action_addrep; }
	when (/^edit$/)   { $action = $action_edit; }
	default {
		printf STDERR "ошибка: неверный параметр: '$command'.\n";
		PrintUsage;
		exit(1);
	}
}

AvgDiaryDirCheck;

$date1 = strftime("%Y_%m_%d", localtime);
$file_new = abs_path($avg_diary_dir."/day_".$date1);

given ($action) {
	when ([	$action_add,
		$action_addrep ])  { FileAddEntry $action; }
	when ($action_edit)      { FileEditEntry; }
	default {
		printf STDERR "ошибка: неизвестный action: '$action'.\n";
		PrintUsage;
		exit(1);
	}
}
