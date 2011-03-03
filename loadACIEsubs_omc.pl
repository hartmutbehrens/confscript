#!/usr/bin/perl -w

# Hartmut Behrens, April 2008 (##)
# subroutines to load ACIE files from ACIE OMC directory into a indexed hash.
# Indexes are definable on all columns of the file

# pragmas 
use warnings;
use strict;
#constants
use constant WARN_ON => 0;
my $acieDir = "/alcatel/var/share/AFTR/ACIE";
if ($^O =~ /mswin/i) {
	$acieDir = "/users/hartmut/perls/confOmc/data";			#testing on Windoze PC
}
my $rnlDir = $acieDir."/ACIE_NLexport_Dir1";
my $emlDir = $acieDir."/ACIE_BLexport";
my $mlDir = $acieDir."/ACIE_MLexport";
mkdir("temp",0777) unless (-e "temp");
mkdir("output",0777) unless (-e "output");

sub loadACIE {
	my ($rel,$where,$hashref,@indexes) = @_;
	#$rel ->relationship to load
	#$where-> RNL or EML ?
	#$hashref: reference to hash in which data will be stored
	#$hashref: if hash has members (keys), only columns which match member key names will be loaded.
	#optional:@indexes-> column names which will be used as key values to the return hash.
	#optional:@indexes-> the order of the columns in @indexes is the order in which the indexes will be created
	#if none are specified, the OMC Index,InstanceIdentifier will be used by default.
	#VERY NB: indexes on columns which don't have unique values across all rows will cause
	#VERY NB: non-unqiue data to be lost.
	die "Specifiy the relationship to load !\n" unless defined($rel);
	die "Specifiy the type of the relationsip (RNL, EML) !\n" unless defined($where);
	my @cols;												#column names from ACIE file.
	my ($ver,$date,$timeOf,$RA,$theOmc);
	my @rest = ();
	my @files;
	my $count = 0;
	if ($where =~ /^RNL/i) {
		print "\tLoading RNL::$rel";
		opendir(DIR,$rnlDir) || die "Could not open NL directory $rnlDir for reading: $!\n";
		@files = map($rnlDir."/$_",grep { /\.csv$/ } readdir(DIR));
		closedir(DIR);
	}
	elsif ($where =~ /^EML/i) {
		print "\tLoading EML::$rel";
		opendir(DIR,$emlDir) || die "Could not open EML directory $emlDir for reading: $!\n";
		my @dir1 = grep { /Dir1$/ } readdir(DIR);
		closedir(DIR);
		foreach my $d (@dir1) {
			opendir(BDIR,$emlDir."/$d");
			my @bssFiles = map($emlDir."/$d"."/$_",grep { /\.csv$/ } readdir(BDIR));
			closedir(BDIR);
			push(@files,@bssFiles);
		}
	}
	elsif ($where =~ /^ML/i) {
		print "\tLoading ML::$rel";
		opendir(DIR,$mlDir) || die "Could not open ML directory $mlDir for reading: $!\n";
		my @dir1 = grep { /Dir1$/ } readdir(DIR);
		closedir(DIR);
		foreach my $d (@dir1) {
			opendir(MDIR,$mlDir."/$d");
			my @mlFiles = map($mlDir."/$d"."/$_",grep { /\.csv$/ } readdir(MDIR));
			closedir(MDIR);
			push(@files,@mlFiles);
		}
	}
	else {
		die "Invalid argument for subroutine loadACIE\n";
	}
	#see if only a subset of columns must be loaded
	#as defined by hash member keys
	my @onlyLoad = ();
	if (%{$hashref}) {
		foreach my $col (keys %{$hashref}) {
			push(@onlyLoad,$col);
			delete(${$hashref}{$col});					#recorded info in array, now clean hash up, since we still need to store data in it !
		}
	}
	
	
	foreach my $acie (@files) {
		my ($who) = ($acie =~ /.*\/(.*?)\.csv/);
		next if ($who ne $rel);
		open(REL,$acie) || die "Error reading $acie: $!\n";
		while (<REL>){
			chomp;
			if ($. == 1) {											#get 1st info line of ACIE file
				($ver,$date,$timeOf,$theOmc,@rest) = split(/;/,$_);
				#$theOmc =~ s/.*?_(.*)/$1/ if ($theOmc =~ /_/);		#EML level files only contain last bit, not A1353RA as with RNL files.
				unless ($theOmc) {
					open(IN,'<'.$rnlDir.'/SubNetwork.csv') || die "Could not open SubNetwork.csv : $!\n";
					my $line = <IN>;
					chomp $line;
					(undef,undef,undef,$theOmc,undef) = split(';',$line);
				}
			}
			elsif ($. == 2) {						      #get column names
				@cols = split(/;/,$_);					#columns are separated by ';'
			}
			else {								            #process data, one row at a time.
				my @data = split(/;/,$_);
				if ($#cols != $#data) {					#check that there is data for each column
					warn "WARNING: $rel: Column count: ",$#cols,"; Data count: ",$#data,"\n" if (WARN_ON);
				}
				my $record = ();					#will be ref to anonymous hash.one row of data, mapped COLUMN NAME -> VALUE
				@{$record}{@cols} = @data;				#load one line of CSV file by hash splice to record
				$record->{"OMC_ID"} = $theOmc;
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
					}
					$evalIndex .= ' = $record';
					eval $evalIndex;				#execute instruction
					die $@ if $@;					  #error in instruction - exit program
				}
				#if no indexes are specified, the OMC Index,InstanceIdentifier will be used by default.
				#good idea, guaranteed to be unique.
				else {
					${$hashref}{$theOmc}{$record->{$rel."InstanceIdentifier"}} = $record;
				}
			}
		}
		close(REL);
	}
	print " ($count entries)\n";
}


1;
__END__
