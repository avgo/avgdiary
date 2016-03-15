#!/usr/bin/perl

BEGIN {
	my $debug = 1;
	@INC = ("./lib", @INC) if $debug == 1;
}

use strict;

use avg_diary::file;
use avg_diary::tags::dirtags;

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
		(my $date, my $time, my $rec, my $tags, my $args) = @_;

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

		my $cur_tags = ${$cur_t_rec}[2];

		if ($#{$tags} != $#{$cur_tags})
		{
			print	"fail\n" .
				"tags != tags\n" .
				"\n";
			exit 1;
		}

		for (my $i = 0; $i <= $#{$tags}; ++$i)
		{
			if (${$tags}[$i] ne ${$cur_tags}[$i])
			{
				print	"fail\n";
				printf	"tags[%d] = '%s'  !=  tags[%d] = '%s'\n",
					$i, ${$tags}[$i], $i, ${$cur_tags}[$i];
				exit 1;
			}
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
				[ ],
			],
			[	"11:12",
				"11:12    2011_02_01_11_12_r2_l1\n" .
				"         2011_02_01_11_12_r2_l2\n" .
				"\n",
				[ ],
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
				[ ],
			],
		],
	], [
		"05.02.2011",
		[
			[	"10:00",
				"10:00    2011_02_05_10_00_r1_l1\n" .
				"         2011_02_05_10_00_r1_l2\n" .
				"\n" .
				"         tags: [t1]\n" .
				"\n",
				[ "t1" ],
			],
			[	"11:12",
				"11:12    2011_02_05_11_12_r2_l1\n" .
				"         2011_02_05_11_12_r2_l2\n" .
				"\n" .
				"         tags: [t2], [t3]\n" .
				"\n",
				[ "t2", "t3" ],
			],
		],
	] );

	for my $x (@arr)
	{
		test2 $x;
	}
}

sub test4 {
	my $tags_dir = $test_dir . "/tags";

	if (! -d $tags_dir) {
		mkdir $tags_dir or die "error: mkdir ($tags_dir): $!\n";
	}

	my @ttc = (
		"t1",
		"t2",
		"t2/t21",
		"t3",
		"t3/t31",
		"t3/t32",
	);

	for my $cd (@ttc)
	{
		my $cd1 = $tags_dir . "/" . $cd;

		if (! -d $cd1) {
			print "creating dir '$cd'.\n";
			mkdir $cd1 or die "tags_dir: mkdir ($tags_dir, $cd): $!\n";
		}
	}

	my $tags = new avg_diary::tags::dirtags;

	$tags->read_tags_from_dir ($test_dir . "/tags");

	printf "checking tags arr ... ";

	if ($#ttc != $#{$tags->{tags}})
	{
		print	"fail\n" .
			"tags != tags\n" .
			"\n";
		exit 1;
	}

	for (my $tag_idx = 0; $tag_idx <= $#{$tags->{tags}}; ++$tag_idx)
	{
		if ($ttc[$tag_idx] ne ${$tags->{tags}}[$tag_idx])
		{
			print	"fail\n" .
			printf	"tags[%d] = '%s'  !=  tags[%d] = '%s'\n",
				$tag_idx, $ttc[$tag_idx],
				$tag_idx, ${$tags->{tags}}[$tag_idx];
			exit 1;
		}
	}

	print "ok.\n";
	print "checking tags hash ...\n";

	for my $tag (@ttc)
	{
		printf	"try to accessing tag %-9s ... ", "'$tag'";

		if ($tags->tag_ex($tag))
		{
			print "ok\n";
		}
		else
		{
			print "fail.\n";
			exit 1;
		}
	}

	print "try to accessing tag 't2/t211' ... ";
	if (!$tags->tag_ex("t2/t211"))
		{ print "ok\n"; }
	else	{ print "fail\n"; exit 1; }

	print "checking tags hash ... ok\n";
}

test3;
test4;
