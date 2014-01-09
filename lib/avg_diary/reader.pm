package avg_diary::reader;

use 5.12.0;
use Carp;
use Cwd qw(abs_path);

use avg_diary::tags;

my $state_init = 1;
my $state_date = 2;
my $state_rec = 3;

sub new {
	my ($class, %cnf) = @_;
	my $avg_diary_dir = delete $cnf{avg_diary_dir};

	my $cut_time = delete $cnf{cut_time};
	$cut_time = 0 unless defined $cut_time;

	my $cut_spaces = delete $cnf{cut_spaces};
	$cut_spaces = 0 unless defined $cut_spaces;

	Carp::croak("dont know\n") if not defined ($avg_diary_dir);

	my $self = {
		avg_diary_dir	=> $avg_diary_dir,
		cut_time	=> $cut_time,
		cut_spaces	=> $cut_spaces
	};

	bless $self, $class;
	return $self;
}

sub fetch {
	my $self = shift;

	return if not defined $self->{fd};
	my $fd = $self->{fd};
	my $state = $self->{state};
	my $cur_date = $self->{cur_date};
	my $cur_time = $self->{cur_time};
	my $cur_record;
	my $tags_in_record = [ ];
	my $line_num = $self->{line_num};
	my $cur_file_index = $self->{cur_file_index};
	my $cur_filename = $self->{cur_filename};
	my $files = $self->{files};
	my $cut_time = $self->{cut_time};
	my $cut_spaces = $self->{cut_spaces};

	if ($cur_file_index > $#{$files}) {
		return ;
	}
	if ($state == $state_rec) {
		$cur_record = $self->{cur_record};
	}

	while (my $line = <$fd>) {
		given ($state) {
		when ($state_init) {
			given ($line) {
			when (/^[0-9]{2}\.[0-9]{2}\.[0-9]+/) {
				chomp $line;
				$cur_date = $line;
				$self->{cur_date} = $cur_date;
				$state = $state_date;
			}
			when (/^$/) {
			}
			default {
				Carp::croak sprintf("%s:%u: нарушение синтаксиса.\n", $cur_filename, $line_num);
			}
			}
		}
		when ($state_date) {
			given ($line) {
			when (/^[0-9]{2}\.[0-9]{2}\.[0-9]+/) {
				chomp $line;
				$cur_date = $line;
				$self->{cur_date} = $cur_date;
			}
			when (/^[0-9]{2}:[0-9]{2}/) {
				$line =~ /^([0-9]{2}:[0-9]{2})/;
				$cur_time = $1;
				$self->{cur_time} = $1;

				$line =~ s/^[0-9]{2}:[0-9]{2}/     / if ($cut_time);
				$line =~ s/^ *// if ($cut_spaces);

				$cur_record = $line;
				$state = $state_rec;
			}
			when (/^$/) {
			}
			default {
				Carp::croak sprintf("%s:%u: нарушение синтаксиса.\n", $cur_filename, $line_num);
			}
			}
		}
		when ($state_rec) {
			given ($line) {
			when (/^[0-9]{2}\.[0-9]{2}\.[0-9]+/) {
				chomp $line;
				$self->{cur_date} = $line;
				$self->{state} = $state_date;
				$self->{line_num} = $line_num + 1;
				return {
					tags => $tags_in_record,
					date => $cur_date,
					time => $cur_time,
					record => $cur_record,
					cur_filename => $cur_filename
				};
			}
			when (/^[0-9]{2}:[0-9]{2}/) {
				$line =~ /^([0-9]{2}:[0-9]{2})/;
				$self->{cur_time} = $1;

				$line =~ s/^[0-9]{2}:[0-9]{2}/     / if ($cut_time);
				$line =~ s/^ *// if ($cut_spaces);

				$self->{cur_record} = $line;
				$self->{line_num} = $line_num + 1;
				$self->{state} = $state_rec;
				return {
					tags => $tags_in_record,
					date => $cur_date,
					time => $cur_time,
					record => $cur_record,
					cur_filename => $cur_filename
				};
			}
			when (/^ +tags:/) {
				avg_diary::tags::parse_line_with_tags $tags_in_record, $line,
						sprintf ("%s:%u", $cur_filename, $line_num);
				$line =~ s/^ *// if ($cut_spaces);
				$cur_record = $cur_record.$line;
			}
			default {
				$line =~ s/^ *// if ($cut_spaces);
				$cur_record = $cur_record.$line;
			}
			}
		}
		}
		++$line_num;
	}

	$self->close_day_file;
	++$cur_file_index;
	$self->{cur_file_index} = $cur_file_index;

	if ($cur_file_index <= $#{$files}) {
		$self->open_day_file;
	}
	else {
		delete $self->{cur_filename};
	}

	if ($state == $state_rec) {
		$self->{state} = $state_date;
		return {
			tags => $tags_in_record,
			date => $cur_date,
			time => $cur_time,
			record => $cur_record,
			cur_filename => $cur_filename
		};
	}

	return;
}

sub first {
	(my $self) = @_;

	$self->load_files_list;
	my $files = $self->{files};

	return if (scalar @{$files} == 0);

	$self->close_day_file;

	$self->{cur_file_index} = 0;
	$self->open_day_file;

	$self->{state} = $state_init;
}

sub load_files_list {
	(my $self) = @_;
	my $avg_diary_dir = $self->{avg_diary_dir};
	opendir my $diary_dir_h, $avg_diary_dir or
			Carp::croak("не получается открыть каталог с дневником '$avg_diary_dir'. $!.\n");
	my $files = [];
	my $cur_file;
	while ($cur_file = readdir $diary_dir_h) {
		next if $cur_file eq "." || $cur_file eq "..";
		my $cur_file2 = abs_path($avg_diary_dir."/".$cur_file);
		push @{$files}, $cur_file2 if -f $cur_file2 && $cur_file =~ /^day_/;
	}
	$self->{files} = [ sort @{$files} ];
	closedir $diary_dir_h;
}

sub open_day_file {
	my $self = shift;
	my $files = $self->{files};
	my $cur_file_index = $self->{cur_file_index};
	my $cur_filename = $files->[$cur_file_index];

	open my $fd, "<", $cur_filename or
			Carp::croak("ошибка: не получается открыть файл '$cur_filename'. $!.\n");

	$self->{fd} = $fd;
	$self->{line_num} = 1;
	$self->{cur_filename} = $cur_filename;
}

sub close_day_file {
	my $self = shift;
	my $fd = delete $self->{fd};

	close $fd if defined $fd;
}

1;
