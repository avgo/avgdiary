package avg_diary::tags;

use 5.12.0;
use Carp;




BEGIN {
	use Exporter();
	our (@EXPORT, @EXPORT_OK, @ISA);

	@ISA    = qw(Exporter);
	@EXPORT = qw(
		&parse_line_with_tags
		);
};




sub parse_line_with_tags {
	(my $tags_h, my $line, my $comment) = @_;

	chomp $line;
	$line =~ s/^ *tags: *//g;
	while ($line) {
		if ( ! ($line =~ s/^\[([^\]]*)\][, ]*//)) {
			printf "%s:некорректное определение тега: |%s|%s|\n", $comment, $1, $line;
			$line = "";
		}
		elsif ($1 eq "") {
			printf "пустой тег\n";
		}
		else {
			push @{$tags_h}, $1;
		}
	}
}

1;
