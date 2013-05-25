#!/usr/bin/env perl

# require v5.6;
use 5.12.0;
use strict;
use avg_diary::reader;

sub test1 {
	my $reader = avg_diary::reader->new(avg_diary_dir => '/mnt/flash/diary');

	$reader->first;
	while (my $rec = $reader->fetch) {
		printf "%s\n", $rec->{date};
	}
}

sub test2 {
	my $reader = avg_diary::reader->new(avg_diary_dir => '/mnt/flash/diary');

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

sub view_all {
	my $reader = avg_diary::reader->new(avg_diary_dir => '/mnt/flash/diary');
	my $date_old;

	$reader->first;
	while (my $rec = $reader->fetch) {
		my $date = $rec->{date};

		if ($date ne $date_old) {
			printf "%s\n\n", $date;
			$date_old = $date;
		}

		printf "%s", $rec->{record};
	}
}




view_all;
