#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# Identify sites with a BCCH on a muliRate RSL AND only one TRE installed.
use strict;
use warnings;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";

#first identify all multiRate configured RSL's
my %lapd = (
	"AlcatelLapdLinkInstanceIdentifier"	=>1,				#only load these columns
	"SpeechCodingRate"			=>1,
	"UserLabel"				=>1
	);
	
my %bbt = (
	"AlcatelBasebandTransceiverInstanceIdentifier"	=>1,
	"RelatedTelecomLapdLink"			=>1,
	"ListOfRadioChannels"				=>1,
	"TRX"						=>1
	);
	
my %sector = (
	"AlcatelBts_SectorInstanceIdentifier"	=>1,
	"NbrDR_GSM900_TRE"			=>1,
	"NbrDR_GSM1800_1900_TRE"		=>1,
	"CellGlobalIdentity"			=>1,
	"UserLabel"				=>1
	);
	
my %rnlBsc = (
	"RnlAlcatelBSCInstanceIdentifier"	=>1,				#only load these columns
	"UserLabel"			=>1
	);
	
	
print "--Gathering BCCH on MultiRate RSL info--\n";
&loadACIE("AlcatelLapdLink","eml",\%lapd);
&loadACIE("AlcatelBasebandTransceiver","eml",\%bbt);
&loadACIE("AlcatelBts_Sector","eml",\%sector);
&loadACIE("RnlAlcatelBSC","rnl",\%rnlBsc);

#process BBT's
#spool BCCH on multiRate RSL CSV output
open(BCMUL,">".$config{"OUTPUT_CSV"}."bcchMultiRate.csv") || die "Cannot open a925.csv: $!\n";
print BCMUL "OMC_ID;BSC_NAME;SITE;LAC;CI;RSL;TRX\n";
foreach my $omc (sort keys %bbt) {
	foreach my $id (sort keys %{$bbt{$omc}}) {
		next if not defined($id);
		#{ sectorID { bsmID { amecID 10, moiRdn 1}, moiRdn 1}, moiRdn 1}
		my ($sectorId) = ($id =~ /\{\ssectorID\s(\{.*\}),\smoiRdn\s\d+\}/);
		my $telecomLink = $bbt{$omc}{$id}{"RelatedTelecomLapdLink"};
		$telecomLink =~ s/relatedObject\://;
		#find main BCCH TRX.
		my $channels = $bbt{$omc}{$id}{"ListOfRadioChannels"};
		if ($channels =~ /bcch/i) {
			#BCCH TRX found, now get RSL rate config
			my $rate = $lapd{$omc}{$telecomLink}{"SpeechCodingRate"};
			my ($bscId) = ($sectorId =~ /.*?amecID\s(\d+).*?/);
			next if not defined($rate);
			if ($rate =~ /multirate/i) {
				my $nbr_DR_GSM = $sector{$omc}{$sectorId}{"NbrDR_GSM900_TRE"};
				my $nbr_DR_DCS = $sector{$omc}{$sectorId}{"NbrDR_GSM1800_1900_TRE"};
				my $rsl = $lapd{$omc}{$telecomLink}{"UserLabel"};
				$rsl =~ s/\"//g;
				$rsl =~ s/RSL//;
				my $trx = $bbt{$omc}{$id}{"TRX"};
				$trx =~ s/trx\://;
				my $bscName = $rnlBsc{$omc}{$bscId}{"UserLabel"};
				next if not defined($bscName);
				$bscName =~ s/\"//g;
				my $site = $sector{$omc}{$sectorId}{"UserLabel"};
				$site =~ s/\"//g;
				my $globalId = $sector{$omc}{$sectorId}{"CellGlobalIdentity"};
				my ($lac,$ci) = ($globalId =~ /lac\s(\d+).*?ci\s(\d+).*?/);
				if (($nbr_DR_GSM > 0) || ($nbr_DR_DCS > 0)) {
					print BCMUL "$omc;$bscName;$site;$lac;$ci;$rsl;$trx\n";
				}
			}
		}
	}
}
close BCMUL;
print "END:--Gathering BCCH on MultiRate RSL info--:END\n";
__END__
