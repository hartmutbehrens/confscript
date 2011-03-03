#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# compile SDCCH allocation info

use strict;
use warnings;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";


my %cell = ();
my %rnlCell = (
	"CellInstanceIdentifier"	=>1,
	"RnlSupportingSector"		=>1,
	"UserLabel" =>1
	);

my %bbt = (
	"AlcatelBasebandTransceiverInstanceIdentifier"	=>1,
	"ListOfRadioChannels"				=>1,
	"Tei"						=>1
	);

my %rnlBsc = (
	"RnlAlcatelBSCInstanceIdentifier" =>1,
	"UserLabel" => 1
	);
print "--Compiling SDCCH Information--\n";
loadACIE("Cell","rnl",\%rnlCell);
loadACIE("RnlAlcatelBSC","rnl",\%rnlBsc);

foreach my $omc (keys %rnlCell) {
	foreach my $id (keys %{$rnlCell{$omc}}) {
		my ($rnlS,$name) = @{$rnlCell{$omc}{$id}}{qw/RnlSupportingSector UserLabel/};
		$name =~ s/\"//g;
		my ($bsc,$bts,$sect) = ($rnlS =~ /bsc\s(\d+),\sbtsRdn\s(\d+).*?sectorRdn\s(\d+)/);
		$cell{$omc}{$bsc}{$bts}{$sect} = $name;
	}
}

loadACIE("AlcatelBasebandTransceiver","eml",\%bbt);
#spool SDCCH CSV info
open(SDCCH,">".$config{"OUTPUT_CSV"}."sdcchConfig.csv") || die "Cannot open sdcchConfig.csv: $!\n";
print SDCCH "OMC_ID;BSC;BTS;SECTOR;TRX;NBR_SDCCH;DYNAMIC;BSC_NAME;CELL_NAME;\n";
foreach my $omc (sort keys %bbt) {
	#next if ($omc != 2);
	foreach my $id (keys %{$bbt{$omc}}) {
		#example { sectorID { bsmID { amecID 1, moiRdn 1}, moiRdn 1}, moiRdn 1}
		my ($bsc,$bts,$sector) = ($id =~ /amecID\s(\d+).*?moiRdn\s(\d+).*?moiRdn\s(\d+)/);
		#next if ($bsc != 67);
		my $channels = $bbt{$omc}{$id}{"ListOfRadioChannels"};
		my $tei = $bbt{$omc}{$id}{'Tei'};
		#print "TEI : $tei\n";
		my ($sdcch,$dynamic) = process_radioChannels($channels);
		if ( (not defined($rnlBsc{$omc}{$bsc}{'UserLabel'})) || (not defined($cell{$omc}{$bsc}{$bts}{$sector})) ) {
			next;
			print "$omc;".$bsc.";".$bts.";".$sector.";".$tei.";".$sdcch.";".$dynamic.";".$rnlBsc{$omc}{$bsc}{'UserLabel'}.";".$cell{$omc}{$bsc}{$bts}{$sector}."\n";
		}
		
		print SDCCH "$omc;".$bsc.";".$bts.";".$sector.";".$tei.";".$sdcch.";".$dynamic.";".$rnlBsc{$omc}{$bsc}{'UserLabel'}.";".$cell{$omc}{$bsc}{$bts}{$sector}."\n";
	}
}
close SDCCH || die "Cannot close sdcchConfig.csv: $!\n";
print "--END:Compiling SDCCH Information:END--\n";


sub process_radioChannels {
	my ($channels) = @_;
	my $sd_count = 0;
	my $dynamic = 0;
	while ($channels =~ /\ssDCCHwithCBCH,/g) {
		$sd_count += 7;
	}
	while ($channels =~ /\ssDCCH,/g) {
		$sd_count += 8;
	}
	while ($channels =~ /\sbCCHCombined,/g) {
		$sd_count += 4;
	}
	while ($channels =~ /\sbCCHwithCBCH,/g) {
		$sd_count += 3;
	}
	while ($channels =~ /\sdynSDCCH,/g) {
		$sd_count += 8;
		$dynamic = 1;
	}
	return ($sd_count,$dynamic);
}



sub process_rnlsector {
	my ($rnlid,$cellid) = @_;
	my $bsc = 0;my $bts = 0;
	my $sector = 0;
	my $pattern = "{\\sbsc\\s(\\d+),\\sbtsRdn\\s(\\d+)},\\ssectorRdn\\s(\\d+)}";
	while ($rnlid =~ /$pattern/g) {
		$bsc = $1;
		$bts = $2;
		$sector = $3;
	}
	$cell{$cellid}{'BSC'} = $bsc;
	$cell{$cellid}{'BTS'} = $bts;
	$cell{$cellid}{'SECTOR'} = $sector;
}