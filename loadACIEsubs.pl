#!/usr/bin/perl -w
#!c:/Perl/bin/Perl.exe -w

# Hartmut Behrens
# subroutines to load ACIE files from file-in-archive, into a indexed hash.
# Indexes are definable on all columns of the file

# modules 
use Archive::Tar;
use Data::Dumper;
# pragmas 
use warnings;
use strict;
#constants
use constant WARN_ON => 0;
# variables
my @filetypes = qw(rnl eml ml);
my %config = ();


#mapping of OMC RA Instance to omc index (as specified in .ini file)
my %omcr = ();
my %dir = ('rnl' => 'data/rnl/',
					 'eml' => 'data/eml/',
					 'ml'	=> 'data/ml/');

my %load = ('rnl' => 'NlSCExport.tgz',
					 'eml' => 'BlExport.tgz',
					 'ml'	=> 'MlExport.tgz');


require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");

%config = %{$href};


sub loadACIE {
	my ($rel,$where,$hashref,@indexes) = @_;
	
	my @cols;												#column names from ACIE file.
	my $tar = Archive::Tar->new();
	my $activeDir = $dir{lc($where)};
	my ($ver,$date,$timeOf,$RA);
	
	my $count = 0;
	opendir(DIR,$activeDir) || die "Could not open $where directory $activeDir for reading: $!\n";
	my @files = grep { /$load{lc($where)}/ } readdir(DIR);
	closedir(DIR);
	
	#see if only a subset of columns must be loaded
	#as defined by hash member keys
	my @onlyLoad = ();
	if (%{$hashref}) {
		foreach my $col (keys %{$hashref}) {
			push(@onlyLoad,$col);
			delete(${$hashref}{$col});					#recorded info in array, now clean hash up !
		}
	}
	print "\tLoading $where :: $rel\n";
	foreach my $archive (@files) {
		$tar->read($activeDir.$archive,1);					#read contents of Export file into memory
		my @filesIn = $tar->list_files;
		my ($cOmc) = ($archive =~ /^(\d).*/);
		next unless grep {/$rel/i} @filesIn;
		$tar->extract($rel.".csv");
		open(REL,$rel.".csv") || die "Error reading ".$rel.".csv: $!\n";
		while (<REL>){
			chomp;
			if ($. == 1) {							#get 1st info line of ACIE file
				($ver,$date,$timeOf,$RA,undef) = split(/;/,$_);
				unless ($RA =~ /\w+/) {
					$RA = $href->{'OMC'.$cOmc.'_RA1353RAInstance'}; 
				}
			}
			elsif ($. == 2) {						#get column names
				@cols = split(/;/,$_);					#columns are separated by ';'
			}
			else {								#process data, one row at a time.
				my @data = split(/;/,$_);
				if ($#cols != $#data) {					#check that there is data for each column
					warn "WARNING: $rel: Column count: ",$#cols,"; Data count: ",$#data,"\n" if (WARN_ON);
				}
				my $record = ();					#will be ref to anonymous hash.one row of data, mapped COLUMN NAME -> VALUE
				@{$record}{@cols} = @data;				#load one line of CSV file by hash splice to record
				$RA = 'A1353RA_'.$RA unless ($RA =~ /^A1353/);
				$record->{"OMC_ID"} = $RA;
				$record->{"IMPORTDATE"} = $date;			#add Date
				$record->{"OMC_VERSION"} = $ver;			#add version
				$count++;
				if (@onlyLoad) {					#see if only a subset of columns must be loaded
					my $changed = ();
					foreach my $col (@onlyLoad) {
						#die "Column $col does not exist; Possible typo ?\n" unless exists($record->{$col});
						if (exists($record->{$col})) {
							${$changed}{$col} = $record->{$col};
						}
						else {
							${$changed}{$col} = "Warning: Column $col was not found";
						}
					}
					$record = $changed;
				}
				#@indexes-> column names which will be used as key values to the return hash.
				if (@indexes) {
					my $evalIndex = '${$hashref}';
					foreach (@indexes) {
						die "Index on \'$_\' is not possible: Column \'$_\' does not exist in $rel OR has been requested to be removed!\n" unless defined($record->{$_});
						$evalIndex .= '{$record->{'.$_.'}}';
						#$HASH{COL1}{COL2}{COL3}{etc..} = info for one row
					}
					$evalIndex .= ' = $record';
					eval $evalIndex;				#execute instruction
					die $@ if $@;					#error in instruction - exit program
				}
				#if no indexes are specified, the OMC Index,InstanceIdentifier will be used by default.
				#good idea, guaranteed to be unique.
				else {
					${$hashref}{$RA}{$record->{$rel."InstanceIdentifier"}} = $record;
				}
			}
		}
		close(REL);
	}
	print "\t\tLoaded $count rows\n";
	#delete LAST file
	#unlink($rel.".csv") || die "Could not delete ".$rel.".csv: $!\n";
	unlink($rel.".csv");
	return ($count);
}


1;
__END__
