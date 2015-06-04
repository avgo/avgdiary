package avg_diary::fb2::normal;

use strict;
use avg_diary::reader;




BEGIN {
	use Exporter();
	our (@EXPORT, @EXPORT_OK, @ISA);

	@ISA    = qw(Exporter);
	@EXPORT = qw(
		&fb2_normal
		);
};




sub fb2_normal {
	(my $avg_diary_dir, my $filename) = @_;
	
	my $reader = avg_diary::reader->new(
			avg_diary_dir => $avg_diary_dir,
			cut_time => 1,
			cut_spaces => 1);
	$reader->first;
	open my $fd, ">", $filename or
			die "ошибка: не получается создать файл '$filename'. $!.\n";
	printf $fd
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n".
		"<FictionBook xmlns=\"http://www.gribuser.ru/xml/fictionbook/2.0\" xmlns:l=\"http://www.w3.org/1999/xlink\">\n".
		"<body>\n";
	my $date_last;
	while (my $rec = $reader->fetch) {
		my $date = $rec->{date};
		if ($date ne $date_last) {
			printf	$fd
				"</section>\n" if $date_last ne "";
			printf	$fd
				"<section>\n".
				"<title>\n".
				"  <p>%s</p>\n".
				"</title>\n", $date;
			$date_last = $date;
		}

		my $time = $rec->{time};
		my $record = $rec->{record};
		$record =~ s/&/&amp;/g;
		$record =~ s/</&lt;/g;
		$record =~ s/>/&gt;/g;
		$record =~ s/$/<\/v>/mg;
		$record =~ s/^/  <v>/mg;

		printf $fd
			"<p>\n".
			"  <strong>%s</strong>\n".
			"</p>\n".
			"<poem>\n".
			"<stanza>\n".
			"%s\n".
			"</stanza>\n".
			"</poem>\n",
			$time, $record;
	}
	printf $fd
		"</section>\n".
		"</body>\n".
		"</FictionBook>\n";
	close $fd;
}

1;
