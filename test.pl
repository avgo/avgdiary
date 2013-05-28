#!/usr/bin/env perl

# require v5.6;
use 5.12.0;
use strict;
use avg_diary::reader;
use Cwd qw(abs_path);




my $avg_diary_dir = abs_path('/media/F085-5411/diary/');

my $m_red;
my $m_green;
my $m_e;
my $mark_red = "\033[31m";
my $mark_green = "\033[32m";
my $mark_e = "\033[0m";


sub color_enable($) {
	if (shift) {
		$m_red = $mark_red;
		$m_green = $mark_green;
		$m_e = $mark_e;
	}
	else {
		$m_red = "";
		$m_green = "";
		$m_e = "";
	}

}

sub test1 {
	my $reader = avg_diary::reader->new(avg_diary_dir => $avg_diary_dir);

	$reader->first;
	while (my $rec = $reader->fetch) {
		printf "%s\n", $rec->{date};
	}
}

sub test2 {
	my $reader = avg_diary::reader->new(avg_diary_dir => $avg_diary_dir);

	my $tags_in_record;
	my $rec;

	$reader->first;

	return if (!($rec = $reader->fetch));

	printf "%s\n", $rec->{date};

	for my $ck (keys %{$reader}) {
		printf "'%s' => '%s'\n", $ck, $reader->{$ck};
	}

	$reader->first;
}

sub test3_view_all {
	my $reader = avg_diary::reader->new(
			avg_diary_dir => $avg_diary_dir,
			cut_time => 0,
			cut_spaces => 0);
	my $date_old;
	my $display_time = 0;

	color_enable(0);

	$reader->first;
	while (my $rec = $reader->fetch) {
		my $date = $rec->{date};

		if ($date ne $date_old) {
			printf "%s%s%s\n\n", $m_red, $date, $m_e;
			$date_old = $date;
		}
		printf "%s%s",
			($display_time) ? sprintf("%s%s%s\n\n", $m_green, $rec->{time}, $m_e):"",
			$rec->{record};
	}
}

sub test3_view_all2 {
	exec "bash", "-c", sprintf("cat \$(ls %s/day_*) | less", $avg_diary_dir);
}

sub test3 {
	exec "bash", "-c",
		"./test.pl --view-all > /tmp/1.txt && ".
		"./test.pl --view-all2 > /tmp/2.txt && ".
		"diff -q /tmp/1.txt /tmp/2.txt && ".
		"echo success || echo fail";
}




if (scalar @ARGV == 1) {
	my $proc_name = shift @ARGV;
	my %tbl = (
		"--test3" => \&test3,
		"--view-all" => \&test3_view_all,
		"--view-all2" => \&test3_view_all2,
	);
	my $proc = $tbl{$proc_name};
	die sprintf("ошибка: нет такой команды '%s'.\n", $proc_name) if not defined $proc;
	&{$proc};
}
