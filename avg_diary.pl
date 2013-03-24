#!/usr/bin/env perl

# require v5.6;
use 5.12.0;
use strict;
# use warnings;
use Cwd qw(abs_path);
use File::Spec;
use POSIX qw(strftime);




sub PrintUsage {
	my $AppName = $0;
	printf 
		"ДЕЛАЙ ТАК:\n".
		"    $AppName --add         Добавить запись в дневник. Или завести новый.\n".
		"    $AppName --addbook     Добавить запись в дневник (приобрести книгу). Или завести новый.\n".
		"    $AppName --addref      Добавить ссылку в дневник. Или завести новый.\n".
		"    $AppName --addrep      Добавить запись-отчёт в дневник. Или завести новый.\n".
		"    $AppName --addtask     Добавить задачу в дневник. Или завести новый.\n".
		"    $AppName --edit        Редактировать сегодняшнюю запись.\n".
		"    $AppName --help        Вывести справку.\n".
		"    $AppName --filename    Вывести имя текущего файла.\n".
		"    $AppName --view-all    Читать весь дневник.\n";
}




if (scalar @ARGV != 1) {
	PrintUsage;
	exit 1;
}

my $avg_diary_dir = $ENV{avg_diary_dir};

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

my $date1 = strftime("%Y_%m_%d", localtime);
my $file_new = abs_path($avg_diary_dir."/day_".$date1);




sub FileAddEntry {
	my $prefix = shift;
	my $prefix2 = "";
	
	given ($prefix) {
		when (/rep/) {
			$prefix2 = "[ОТЧЁТ]    ";
		}
	}
	
	printf "$prefix2\n";
}

sub FileEditEntry {
	
}




my $command = $ARGV[0];
given ($command) {
	when (/^--add$/) {
		FileAddEntry;
	}
	when (/^--addrep$/) {
		FileAddEntry "rep";
	}
	when (/^--edit$/) {
		FileEditEntry;
	}
	default {
		printf STDERR "ошибка: неверный параметр: '$command'.\n";
		PrintUsage;
		exit(1);
	}
}
