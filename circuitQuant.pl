#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# calculate CircuitPack Type Quantities, A925 Transcoder configuration information
use strict;
use warnings;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";

my %circuitQuant = (
	"AlcatelCircuitPackInstanceIdentifier"	=>1,			#only load these columns
	"CircuitPackType"			=>1
	);
my %emlBsc = (
	"AlcatelBscInstanceIdentifier"	=>1,				#only load these columns
	"UserLabel"			=>1
	);
my %btsSite = (
	"AlcatelBtsSiteManagerInstanceIdentifier"	=>1,
	"UserLabel"					=>1
	);
#{ amecID 1, moiRdn 1}


my %count = ();
print "--Calculating CircuitPack Quantities--\n";
&loadACIE("AlcatelCircuitPack","eml",\%circuitQuant);
&loadACIE("AlcatelBsc","eml",\%emlBsc);
&loadACIE("AlcatelBtsSiteManager","eml",\%btsSite);

#calculate Quantities
foreach my $omc (keys %circuitQuant) {
	foreach my $id (keys %{$circuitQuant{$omc}}) {
		my ($bscId,$moiId) = ($id =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
		next if ($moiId < 3);
		$moiId -= 2;
		my $bts = "{ amecID ".$bscId.", moiRdn ".$moiId."}";
		my $name = $btsSite{$omc}{$bts}{'UserLabel'};
		#print "$bts : $name\n";
		my $which = 'REAL';
		$which = 'TEST' if ($name =~ /_test/i);
		$which = 'NEW' if ($name =~ /_new/i);
		$bscId = "{ amecID ".$bscId.", moiRdn 1}";
		my $bscName = $emlBsc{$omc}{$bscId}{"UserLabel"};
		$bscName =~ s/\"//g;
		my $type = $circuitQuant{$omc}{$id}{"CircuitPackType"};
		$count{$omc}{$bscName}{$which}{$type}++;
	}
}



#spool circuitQuant CSV output
open(QUANT,">".$config{"OUTPUT_CSV"}."CircuitQuantities.csv") || die "Cannot open CircuitQuantities.csv: $!\n";
print QUANT "OMC_ID;BSC_NAME;CircuitPackType;Quantity;TYPE\n";
foreach my $omc (sort keys %count) {
	foreach my $bsc (sort keys %{$count{$omc}}) {
		foreach my $which (sort keys %{$count{$omc}{$bsc}}) {
			foreach my $type (sort keys %{$count{$omc}{$bsc}{$which}}) {
				my $count = $count{$omc}{$bsc}{$which}{$type};
				print QUANT "$omc;$bsc;$type;$count;$which\n";
			}
		}
	}
}
close QUANT || die "Cannot close CircuitQuantities.csv: $!\n";
print "--END:Calculating CircuitPack Quantities:END--\n";

__END__
