package avg_diary::fb2::bytags;

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




sub fb2_by_tags {
	my $fb2_filename = shift;

	my $tmp_dir = "/tmp/diary-fb2.tmp";
	system "rm -rf $tmp_dir";
	mkdir $tmp_dir or die sprintf(
			"ошибка: не получается создать каталог '%s'. %s.\n",
			$tmp_dir, $!);
	CheckCreateTagsPath $tags_dir;
	CopyDirStructure $tags_dir, $tmp_dir;
	
	my $reader = avg_diary::reader->new(
			avg_diary_dir => $avg_diary_dir,
			cut_time => 1,
			cut_spaces => 1);
	$reader->first;
	while (my $rec = $reader->fetch) {
		my $tags = $rec->{tags};
		my $date = $rec->{date};
		$date =~ /0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)/;
		my $day_filename = sprintf "day_%04u_%02u_%02u.html", $3, $2, $1;
		if ($#{$tags} >= 0) {
			for my $cur_tag (@{$tags}) {
				my $filename = abs_path(
						$tmp_dir."/".$cur_tag."/".$day_filename);
				fb2_by_tags_write_record_to_file
						$filename,
						$rec->{date},
						$rec->{time},
						$rec->{record};
			}
		}
		else {
			my $filename = abs_path($tmp_dir."/".$day_filename);
			fb2_by_tags_write_record_to_file
					$filename,
					$rec->{date},
					$rec->{time},
					$rec->{record};
		}
	}

	open my $fb2_file, ">", $fb2_filename or die sprintf(
			"ошибка: не получается открыть файл '%s'. %s.\n",
			$fb2_filename, $!);
	printf $fb2_file
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n".
		"<FictionBook xmlns=\"http://www.gribuser.ru/xml/fictionbook/2.0\" xmlns:l=\"http://www.w3.org/1999/xlink\">\n".
		"<body>\n";
	fb2_by_tags_write_records $fb2_file, $tmp_dir, "";
	printf $fb2_file
		"</body>\n".
		"</FictionBook>\n";
	close $fb2_file;
	system "rm -rf $tmp_dir";
}

sub fb2_by_tags_write_records {
	(my $fb2_file, my $dir, my $tag) = @_;

	my @dirs;
	my @files;

	opendir my $dir_h, $dir or die sprintf(
			"ошибка: не получается открыть каталог '%s'. %s.\n",
			$dir, $!);
	while (my $cur_file = readdir $dir_h) {
		next if $cur_file eq "." or $cur_file eq "..";
		my $cur_file2 = abs_path($dir."/".$cur_file);
		if (-d $cur_file2) {
			push @dirs, $cur_file;
		}
		elsif (-f $cur_file2 && $cur_file =~ /^day_/) {
			push @files, $cur_file;
		}
	}
	closedir $dir_h;

	for my $cur_dir (sort @dirs) {
		my $cur_dir2 = abs_path($dir."/".$cur_dir);
		my $cur_tag = ($tag eq "") ? $cur_dir : $tag."/".$cur_dir;
		fb2_by_tags_write_records $fb2_file, $cur_dir2, $cur_tag;
	}

	my $tag_text;

	if ($tag eq "") {
		$tag_text = "без тега";
	}
	else {
		$tag_text = $tag;
		$tag_text =~ s/&/&amp;/g;
		$tag_text =~ s/</&lt;/g;
		$tag_text =~ s/>/&gt;/g;
	}

	printf $fb2_file
		"<section>\n".
		"<title>\n".
		"  <p>%s</p>\n".
		"</title>\n", $tag_text;
	for my $cur_file (sort @files) {
		my $cur_file2 = abs_path($dir."/".$cur_file);
		open my $fd, "<", $cur_file2 or
				die sprintf ("ошибка: не получается открыть файл '%s'. %s.\n",
				$cur_file2, $!);
		while (my $line = <$fd>) { print $fb2_file "  ",$line; }
		close $fd;
	}
	printf $fb2_file "</section>\n";
}

sub fb2_by_tags_write_record_to_file($$$$) {
	(my $filename, my $date, my $time, my $record) = @_;
	my $new_file = (-f $filename) ? 0 : 1;

	$record =~ s/&/&amp;/g;
	$record =~ s/</&lt;/g;
	$record =~ s/>/&gt;/g;
	$record =~ s/$/<\/v>/mg;
	$record =~ s/^/  <v>/mg;

	open my $fd, ">>", $filename or die
		sprintf("ошибка: не получается открыть файл '%s'. %s.\n", $filename, $!);
	printf $fd
		"<p>\n".
		"  <strong>%s</strong>\n".
		"</p>\n",
		$date if $new_file;
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
	close $fd;
}

1;
