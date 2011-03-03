######################################################################
# subs.pl : this is to be required
######################################################################



# read conf.ini and return hash ref containing .ini info
sub read_conf {
	my ($ini) = @_;
	#returns array containing index->OMC
	my $block = "NONE";
	my @indx;
	my %config;
	open(INI, "< $ini") or die "Couldn't open \"$ini\" for reading : $!\n";
	while (<INI>) {
		chomp;
		next if /^#/;                                   #ignore comments
		next if (length($_) == 0);                      #ignore empty lines
		next if /\s+/;                                  #ignore spaces
		#find block header, identified by :[yack yack]
		if (/\[(.*?)\]/) {
			$block = $1;
			if (/OMC(\d+)/) {
				push(@indx,$1);
			}
		}
		#find data,read it into hash
		else {
			@_ = split(/=/,$_);
			$config{$block."_".$_[0]} = $_[1];
		}
	}
	close(INI) or die "Couldn't close $ini : $!\n";
	return (\@indx,\%config);
	
}

1;
