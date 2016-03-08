#!/usr/bin/perl

BEGIN {
	my $debug = 1;
	@INC = ("./lib", @INC) if $debug == 1;
}

use strict;

use avg_diary::file;

my $test_dir = "test";
my $avg_diary_dir = $test_dir;

sub test1 {
	my $af;

	$af = new avg_diary::file (filename => "day_2014_03_15");
	$af = new avg_diary::file (date => "20.00.2016");

	printf	"d: %s\n" .
		"m: %s\n" .
		"y: %s\n" .
		"f: '%s'\n"
		,
		$af->{day}, $af->{month}, $af->{year},
		$af->{filename};
}

sub test2 {
	(my $arr) = @_;

	my $af;

	printf "test %s .. \n", ${$arr}[0];

	$af = new avg_diary::file
			date          => ${$arr}[0],
			avg_diary_dir => $avg_diary_dir;

	my $args = [ $arr, 0 ];

	$af->read (sub {
		(my $date, my $time, my $rec, my $args) = @_;

		# !!! date is not checking !!!

		my $arr = ${$args}[0];
		my $index = \${$args}[1];

		my $arr_date = ${$arr}[0];
		my $arr_t_rec = ${$arr}[1];

		my $cur_test_index = ${$index};

		printf "  checking %d/%d  .. ",
				$cur_test_index + 1,
				scalar @{$arr_t_rec};

		if ($cur_test_index >= scalar @{$arr_t_rec})
		{
			print	"fail\n" .
				"\n" .
				"error: out of range! (day-file has more records\n" .
				"       than records in array.)\n" .
				"\n";

			exit 1;
		}

		my $cur_t_rec = ${$arr_t_rec}[$cur_test_index];

		my $cur_t = ${$cur_t_rec}[0];
		my $cur_rec = ${$cur_t_rec}[1];

		if ($rec ne $cur_rec)
		{
			print	"fail\n" .
				$rec     . "\n" .
				$cur_rec . "\n" .
				"\n";
			exit 1;
		}

		if ($time ne $cur_t)
		{
			print	"fail\n" .
				"TIME GET: " . $time    . "\n" .
				"TIME EXP: " . $cur_t   . "\n" .
				"\n";
			exit 1;
		}

		print "ok\n";

		++${$index};

		return 0;
	}, $args);

	printf "test %s .. ", ${$arr}[0];

	if (${$args}[1] == scalar @{${$arr}[1]})
	{
		printf "ok\n\n";
	}
	else
	{
		printf "fail\n\n";
	}
}

sub test3 {
	my @arr = ( [
		"01.02.2011",
		[
			[	"10:00",
				"10:00    2011_02_01_10_00_r1_l1\n" .
				"         2011_02_01_10_00_r1_l2\n" .
				"\n",
			],
			[	"11:12",
				"11:12    2011_02_01_11_12_r2_l1\n" .
				"         2011_02_01_11_12_r2_l2\n" .
				"\n",
			],
		],
	], [
		"03.02.2011",
		[ ],
	], [
		"04.02.2011",
		[
			[	"12:12",
				"12:12    2011_02_04_12_12_r1_l1\n" .
				"\n",
			],
		],
	] );

	for my $x (@arr)
	{
		test2 $x;
	}
}

test3;
