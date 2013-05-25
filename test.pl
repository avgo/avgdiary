#!/usr/bin/env perl

# require v5.6;
use 5.12.0;
use strict;
use avg_diary::reader;

my $reader = avg_diary::reader->new(avg_diary_dir => '/mnt/flash/diary');

sub test1 {
	$reader->first;
	while ((my $tags_in_record, my $cur_day, my $cur_record) = $reader->fetch) {
		printf "%s\n", $cur_day;
	}
}

sub test2 {
	my $tags_in_record;
	my $cur_day;
	my $cur_record;

	$reader->first;

	if (!(($tags_in_record, $cur_day, $cur_record) = $reader->fetch)) {
		return ;
	}

	printf "%s\n", $cur_day;
	for my $ck (keys %{$reader}) {
		printf "'%s' => '%s'\n", $ck, $reader->{$ck};
	}
	$reader->first;

}

test2;
