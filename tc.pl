#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# gather A925 Transcoder configuration information
use strict;
use warnings;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";

my %circuitQuant = (
	"AlcatelCircuitPackInstanceIdentifier"	=>1,			#only load these columns
	"CircuitPackType"			=>1,
	"AdministrativeState"			=>1,
	"AffectedObjectList"			=>1
	);
my %emlBsc = (
	"AlcatelBscInstanceIdentifier"	=>1,				#only load these columns
	"UserLabel"			=>1
	);
	
my %ttp = (
	"Alcatel2MbTTPInstanceIdentifier"	=>1,
	"TTPtype"				=>1,
	"TtpNumber"				=>1,
	"AdministrativeState"			=>1,
	"UserLabel"				=>1,
	"OperationalState"			=>1
	);

my %a925 = ();
my %summary = ();
my %a925_slot = (
		1	=>2,
		2	=>5,
		3	=>8,
		4	=>11,
		5	=>16,
		6	=>19,
		7	=>22,
		8	=>25,
		9	=>30,
		10	=>33,
		11	=>36,
		12	=>39
		);

print "--Gathering A925 Transcoder Config Information--\n";
&loadACIE("AlcatelCircuitPack","eml",\%circuitQuant);
&loadACIE("AlcatelBsc","eml",\%emlBsc);
&loadACIE("Alcatel2MbTTP","eml",\%ttp);
my %bscConfig = ();
#get SM HWAY NO
foreach my $omc (keys %ttp) {
	foreach my $id (keys %{$ttp{$omc}}) {
		if ($id =~ /amecID\s\d+, moiRdn\s1/) {
			if ($ttp{$omc}{$id}{"TTPtype"} =~ /atermux/) {
				if (($ttp{$omc}{$id}{"AdministrativeState"} =~ /unlocked/) && ($ttp{$omc}{$id}{"OperationalState"} =~ /enabled/)) {
					my ($bscid) = ($id =~ /amecID\s(\d+)/);
					$bscConfig{$omc}{$bscid}{"SMHWAY"}++;
				}
			}
		}
	}
}

#calculate Quantities
#spool a925 CSV output
open(TC,">".$config{"OUTPUT_CSV"}."a925.csv") || die "Cannot open a925.csv: $!\n";
print TC "Region;OMC_ID;BSC;Rack;Shelf;TEI;Slot;Name;Ater;AterMux\n";
foreach my $omc (keys %circuitQuant) {
	foreach my $id (keys %{$circuitQuant{$omc}}) {
		my ($bscId,$rack,$shelf,$slot);
		($bscId) = ($id =~ /amecID\s(\d+)/);
		my $theId = $bscId;
		$bscId = "{ amecID ".$bscId.", moiRdn 1}";
		my $bscName = $emlBsc{$omc}{$bscId}{"UserLabel"};
		$bscName =~ s/\"//g;
		my $type = $circuitQuant{$omc}{$id}{"CircuitPackType"};
		$type =~ s/\"//g;
		my $adState = $circuitQuant{$omc}{$id}{"AdministrativeState"};
		my $affectedObj = $circuitQuant{$omc}{$id}{"AffectedObjectList"};
		if ($adState eq 'unlocked') {
			if ($type =~/(mt120|jbmte3nb|jbmte2)/) {	
				($rack) = ($id =~ /rackRdn\s(\d+)/);
				($shelf) = ($id =~ /shelfRdn\s(\d+)/);
				($slot) = ($id =~ /shelfRdn.*?moiRdn\s(\d+)/);
				my $tei = $shelf*16 + ($slot-1);
				my $tcSlot = $a925_slot{$slot};
				my $slot = $slot + (($shelf-1)*12);
				my (@aters,$atermux);
				($atermux,@aters) = getObjFromString($omc,$affectedObj);
				if (not defined($atermux)) {
					$atermux = '?';
				}
				print TC region($bscName).";$omc;$bscName;$rack;$shelf;$tei;$tcSlot;TCDR $slot;".join(',',@aters).";$atermux\n";
			}
			if ($type =~/(mt120|asmc|jbmte3nb|jbmte2)/) {
				$summary{$omc}{$bscName}{"SMHWAY"} = $bscConfig{$omc}{$theId}{"SMHWAY"};
				$summary{$omc}{$bscName}{"dt16"} = 0 if not exists($summary{$omc}{$bscName}{"dt16"});
				$summary{$omc}{$bscName}{"atbx"} = 0 if not exists($summary{$omc}{$bscName}{"atbx"});
				$summary{$omc}{$bscName}{"asmc"} = 0 if not exists($summary{$omc}{$bscName}{"asmc"});
				$summary{$omc}{$bscName}{"mt120"} = 0 if not exists($summary{$omc}{$bscName}{"mt120"});
				my (@aters,$atermux);
				($atermux,@aters) = getObjFromString($omc,$affectedObj);
				$summary{$omc}{$bscName}{$type}++;
				if ($type =~ /asmc/) {
					$summary{$omc}{$bscName}{"atbx"} = $summary{$omc}{$bscName}{$type}*4;
					$summary{$omc}{$bscName}{"dt16"} = $summary{$omc}{$bscName}{$type}*8;
				}
			}
		}
	}
}
close TC || die "Cannot close a925.csv: $!\n";
open(TCSUM,">".$config{"OUTPUT_CSV"}."tcSummary.csv") || die "Cannot open tcSummary.csv: $!\n";
print TCSUM "OMC_ID;REGION;BSC;SMHW;MT120;ASMC;ATBX;DT16\n";
foreach my $omc (sort keys %summary){
	foreach my $BSC (sort keys %{$summary{$omc}}) {
		my $region = region($BSC);
		print TCSUM "$omc;$region;$BSC;".$summary{$omc}{$BSC}{"SMHWAY"}.";".$summary{$omc}{$BSC}{"mt120"}.";".$summary{$omc}{$BSC}{"asmc"}.";".$summary{$omc}{$BSC}{"atbx"}.";".$summary{$omc}{$BSC}{"dt16"}."\n";
	}
}
close TCSUM || die "Cannot close tcSummary.csv: $!\n";

print "--END:Gathering A925 Transcoder Config Information:END--\n";

sub getObjFromString {
	my ($omc, $obj) = @_;
	my (@objs,@aters,$atermux);
	@objs = ($obj =~ /(\{\sameID\s\{.*?\}.*?\})\,\s/g);
	foreach (@objs) {
		if ($ttp{$omc}{$_}{"TTPtype"} eq 'a') {
			push(@aters,$ttp{$omc}{$_}{"TtpNumber"})
		}
		elsif ($ttp{$omc}{$_}{"TTPtype"} eq 'atermux') {
			$atermux = $ttp{$omc}{$_}{"TtpNumber"};
		}
	}
	return($atermux,@aters);
}

sub region {
	my ($n) = @_;
	my %na = (
		'W'	=> 'WESTERN',
		'E' => 'EASTERN',
		'C' => 'CENTRAL'
		);
		return $na{substr($n,0,1)}
}

__END__