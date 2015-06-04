package avg_diary::tags;

use 5.12.0;
use Carp;




BEGIN {
	use Exporter();
	our (@EXPORT, @EXPORT_OK, @ISA);

	@ISA    = qw(Exporter);
	@EXPORT = qw(
		&parse_line_with_tags
		&tags_check
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

sub tags_check {
	(my $tags, my $tags_in_file) = @_;
	my $result = 1;

	for my $ct1 (@{$tags_in_file}) {
		my $finded = 0;
		for my $ct2 (@{$tags}) {
			if ($ct1 eq $ct2) {
				$finded = 1
			}
		}
		if ($finded == 0) {
			$result = 0;
			printf "предупреждение: тег '$ct1' не определён в множестве тегов.\n";
		}
	}
	return $result;
}

1;
