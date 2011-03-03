#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# get a list of dt16 cards where the control status is abnormal - usually indicates faulty TS
use strict;
use warnings;

#constants
use constant CELL_NAME_SIZE => 18;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";

my %status = (
	'{0}'	=> "subjectToTest",
	'{1}'	=> "partOfServicesLocked",
	'{2}'	=> "reservedForTest",
	'{3}'	=> "suspended"
	);
my %circuitQuant = (
	"AlcatelCircuitPackInstanceIdentifier"	=>1,			#only load these columns
	"CircuitPackType"			=>1,
	"ControlStatus"				=>1
	);
	
my %emlBsc = (
	"AlcatelBscInstanceIdentifier"	=>1,				#only load these columns
	"UserLabel"			=>1
	);

print "--Creating DT16 Control Status Report--\n";	
&loadACIE("AlcatelCircuitPack","eml",\%circuitQuant);
&loadACIE("AlcatelBsc","eml",\%emlBsc);

open(DT16,">".$config{"OUTPUT_CSV"}."dt16.csv") || die "Cannot open dt16.csv: $!\n";
print DT16 "OMC;BSC_NAME;RACK;SHELF;SLOT;CONTROL_STATUS\n";
foreach my $omc (keys %circuitQuant) {
	foreach my $id (keys %{$circuitQuant{$omc}}) {
		my ($bscId);
		($bscId) = ($id =~ /amecID\s(\d+)/);
		$bscId = "{ amecID ".$bscId.", moiRdn 1}";
		my $bscName = $emlBsc{$omc}{$bscId}{"UserLabel"};
		$bscName =~ s/\"//g;
		my $type = $circuitQuant{$omc}{$id}{"CircuitPackType"};
		my $status = $circuitQuant{$omc}{$id}{"ControlStatus"};
		if ($status ne '{}') {
			my ($rack,$shelf,$slot) = ($id =~ /.*?rackRdn\s(\d+),shelfRdn\s(\d+)\}\,\smoiRdn\s(\d+)/);
			print DT16 "$omc;$bscName;$rack;$shelf;$slot;$status{$status}\n";
		}
	}
}



close DT16;
print "--END:Creating DT16 Control Status Report:END--\n";	
__END__