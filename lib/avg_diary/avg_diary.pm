package avg_diary::avg_diary;

use strict;

use avg_diary::file;




BEGIN {
	use Exporter();
	our (@EXPORT, @EXPORT_OK, @ISA);

	@ISA    = qw(Exporter);
	@EXPORT = qw(
		dayfile_name_to_date
	);
};




sub new {
	(my $class, my %cnf) = @_;

	my $avg_diary_dir = delete $cnf{avg_diary_dir};

	die	$class . "->new() error: 'avg_diary_dir' parameter is unset.\n"
		if not defined $avg_diary_dir;

	die	$class . "->new() error: invalid 'avg_diary_dir' parameter.\n" .
		"'avg_diary_dir' parameter must be a valid directory.\n"
		if not -d $avg_diary_dir;

	my $self = bless {
		avg_diary_dir => $avg_diary_dir,
		tags_dir      => $avg_diary_dir . "/tags",
	}, $class;

	return $self;
}

sub day_filename {
	(my $self, my $year, my $month, my $day) = @_;

	my $file = $self->{avg_diary_dir} . "/" . sprintf (
			"day_%04u_%02u_%02u", $year, $month, $day);

	return $file;
}

sub dayfile_name_to_date {
	my $dayfile_name = shift ;

	$dayfile_name =~ /day_([0-9]+)_([0-9]+)_([0-9]+)$/
		or return ;

	return ( $1, $2, $3 ) ;
}

sub dayfiles {
	(my $self) = @_;

	opendir my $fd, $self->{avg_diary_dir} or die
		"error: can't open avgdiary dir '" .
		$self->{avg_diary_dir} . "'.\n";

	my $dayfiles = [ ];

	while ( my $file = readdir $fd )
	{
		my $file_rp = $self->{avg_diary_dir} . "/" . $file;

		next if not -f $file_rp or
			not $file =~ /^day_[0-9]{4}.[0-9]{2}.[0-9]{2}$/;

		push @{$dayfiles}, $file;
	}

	@{$dayfiles} = sort @{$dayfiles};

	return $dayfiles;
}

sub dayfiles_tagged {
	(my $self, my $tag) = @_;

	my $dayfiles = $self->dayfiles ;

	return $dayfiles if not defined $tag ;

	my $dayfiles_tagged = [ ];

	my $args = {
		dayfiles_tagged => $dayfiles_tagged,
		tag             => $tag,
	};

	for my $dayfile ( @{$dayfiles} )
	{
		my $file = avg_diary::file->new (
			filename => $self->{avg_diary_dir} . "/" . $dayfile
		);

		$args->{dayfile} = $dayfile ;

		$file->read ( sub
		{
			(my $date, my $time, my $rec, my $tags,
				my $rec_line, my $rec_line_e, my $args) = @_;

			my $tag = $args->{tag};

			return AVG_DIARY_FILE_READ
				if not grep /^$tag(\/|$)/, @{$tags};

			push @{$args->{dayfiles_tagged}}, $args->{dayfile};

			return AVG_DIARY_FILE_READ_BREAK;
		}, $args );
	}

	return $dayfiles_tagged ;
}

sub get_tags_dir {
	(my $self) = @_;

	return $self->{tags_dir};
}

1;
