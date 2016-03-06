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
		(my $date, my $rec, my $args) = @_;

		# !!! date is not checking !!!

		my $arr = ${$args}[0];
		my $index = \${$args}[1];

		my $arr_date = ${$arr}[0];
		my $arr_rec = ${$arr}[1];

		my $cur_test_index = ${$index};

		printf "checking %d/%d .. ",
				$cur_test_index + 1,
				scalar @{$arr_rec};

		my $cur_rec = ${$arr_rec}[$cur_test_index];

		die	"fail\n" .
			$rec     . "\n" .
			$cur_rec . "\n" .
			"\n"
			if $rec ne $cur_rec;

		print "ok\n";

		++${$index};

		return 0;
	}, $args);

	printf "test %s .. ", ${$arr}[0];

	if (${$args}[1] == scalar @{${$arr}[1]})
	{
		printf "ok\n";
	}
	else
	{
		printf "fail\n";
	}
}

sub test3 {
	my @arr = ( [
		"01.02.2011",
		[
			"10:00    2011_02_01_10_00_r1_l1\n" .
			"         2011_02_01_10_00_r1_l2\n" .
			"\n",
			"11:12    2011_02_01_11_12_r2_l1\n" .
			"         2011_02_01_11_12_r2_l2\n" .
			"\n",
		],
	], [
		"03.02.2011",
		[ ],
	] );

	for my $x (@arr)
	{
		test2 $x;
	}
}

# test2 "01.02.2011";

test3;
