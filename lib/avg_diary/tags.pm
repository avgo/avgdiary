package avg_diary::tags;

use 5.12.0;
use Carp;
use Cwd qw(abs_path);




BEGIN {
	use Exporter();
	our (@EXPORT, @EXPORT_OK, @ISA);

	@ISA    = qw(Exporter);
	@EXPORT = qw(
		&parse_line_with_tags
		&tags_check
		&tags_load_from_file
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

sub tags_load_from_file {
	(my $tags, my $tags_root, my $tags_dir) = @_;

	my @files;
	my $tags_root_dir = $tags_root . "/" . $tags_dir;

	opendir my $tags_dir_h, $tags_root_dir or die "Не получается открыть каталог '$tags_root_dir'. $!\n";

	while (my $cur_dir = readdir $tags_dir_h) {
		next if $cur_dir eq "." or $cur_dir eq "..";
		my $cur_dir2 = $tags_root_dir . "/" . $cur_dir;
		next if not -d $cur_dir2;
		push @files, $cur_dir;
	}

	closedir $tags_dir_h;

	@files = sort @files;

	for my $cur_dir (@files) {
		my $tags_dir2;

		if (defined $tags_dir) {
			$tags_dir2 = $tags_dir . "/" . $cur_dir;
		}
		else {
			$tags_dir2 = $cur_dir;
		}

		push @{$tags}, $tags_dir2;
		tags_load_from_file($tags, $tags_root, $tags_dir2);
	}
}

1;
