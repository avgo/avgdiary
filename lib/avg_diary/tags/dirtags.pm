package avg_diary::tags::dirtags;

use strict;

sub new {
	(my $class) = @_;

	my $self = bless {
		tags   => [ ],
		tags_h => { },
	}, $class;

	return $self;
}

sub read_tags_from_dir {
	(my $self, my $tags_root, my $tags_dir) = @_;

	my @files;
	my $tags_root_dir = $tags_root . "/" . $tags_dir;

	opendir my $tags_dir_h, $tags_root_dir or die "error: Can't open directory '$tags_root_dir'. $!.\n";

	while (my $cur_dir = readdir $tags_dir_h)
	{
		next if $cur_dir eq "." or $cur_dir eq "..";
		my $cur_dir2 = $tags_root_dir . "/" . $cur_dir;
		next if not -d $cur_dir2;
		push @files, $cur_dir;
	}

	closedir $tags_dir_h;

	@files = sort @files;

	for my $cur_dir (@files)
	{
		my $tags_dir2;

		if (defined $tags_dir)
		{
			$tags_dir2 = $tags_dir . "/" . $cur_dir;
		}
		else
		{
			$tags_dir2 = $cur_dir;
		}

		push @{$self->{tags}}, $tags_dir2;

		${$self->{tags_h}}{$tags_dir2} = 1;

		$self->read_tags_from_dir($tags_root, $tags_dir2);
	}
}

sub tag_ex {
	(my $self, my $tag) = @_;

	return ${$self->{tags_h}}{$tag};
}

1;
