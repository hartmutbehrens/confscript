#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# Create EDGE planning csv
use strict;
use warnings;

use Data::Dumper;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};

my @cols;
my %line = ();
open(BSC,"<".$config{"OUTPUT_CSV"}."bscConfig.csv") || die "Cannot open bscConfig.csv: $!\n";
my %bsc = ();
while (<BSC>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		$bsc{$line{"OMC_ID"}}{$line{"BSC_ID"}}{"CONFIG"} = $line{"CONFIG"};
		$bsc{$line{"OMC_ID"}}{$line{"BSC_ID"}}{"NAME"} = $line{"NAME"};
	}
}
close(BSC) || die "Cannot close bscConfig.csv: $!\n";


open(LAPD,"<".$config{"OUTPUT_CSV"}."lapdConfig.csv") || die "Cannot open lapdConfig.csv: $!\n";
my %lapd = ();
while (<LAPD>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my $ci = $line{"CI"};
		my $id = $line{"AlcatelLapdLinkInstanceIdentifier"};
		
		@{$lapd{$ci}{$id}}{qw/LapdLinkUsage SpeechCodingRate TSU SiteName ABIS_TOPOLOGY/} = @line{qw/LapdLinkUsage SpeechCodingRate TSU SiteName ABIS_TOPOLOGY/};
		
	}
}
close(LAPD) || die "Cannot close lapdConfig.csv: $!\n";


my %BTS = ();
open(BTS,"<".$config{"OUTPUT_CSV"}."btsConfig.csv") || die "Cannot open ".$config{"OUTPUT_CSV"}."btsConfig.csv: $!\n";
while (<BTS>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;							
		my ($lac,$ci) = @line{qw/LAC CI/};
		@{$BTS{$ci}}{qw/Cell_Name Site_Name Abis_TS_Free RANK OMC BSC_ID/} = @line{qw/Cell_Name Site_Name Abis_TS_Free RANK OMC BSC_ID/};
		
	}
}
close(BTS) || die "Cannot close btsConfig.csv: $!\n";

my %RSL = ();
open(RSL,"<".$config{"OUTPUT_CSV"}."rslConfig.csv") || die "Cannot open rslConfig.csv: $!\n";
while (<RSL>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my ($omc,$bsc,$tsu,$tcu) = @line{qw/OMC_ID BSC_NAME TSU TCU/};
		@{$RSL{$omc}{$bsc}{$tsu}{$tcu}}{qw/RSL_NO OML_NO SD_COUNT TCU_LOAD POOL_USABLE/} = @line{qw/RSL_NO OML_NO SD_COUNT TCU_LOAD POOL_USABLE/};
		
	}
}
close(RSL) || die "Cannot close rslConfig.csv: $!\n";

my %info = ();
my %abisCount = ();
my %cellCount = ();
my %seenAbis = ();
foreach my $ci (sort keys %lapd) {
	next if ($ci eq '-');
	next if ($ci == 65535);
	my $omc = $BTS{$ci}{"OMC"};
	
	my $bsc = $bsc{$omc}{$BTS{$ci}{"BSC_ID"}}{'NAME'};
	my $config = $bsc{$omc}{$BTS{$ci}{"BSC_ID"}}{"CONFIG"};
	
	my $tsFree = $BTS{$ci}{"Abis_TS_Free"};
	my $rank = $BTS{$ci}{"RANK"};
	#print "$omc : $bsc : $rank\n";
	foreach my $id (keys %{$lapd{$ci}}) {
		my $rate = $lapd{$ci}{$id}{"SpeechCodingRate"};
		my $usage = $lapd{$ci}{$id}{"LapdLinkUsage"};
		next if ($usage ne 'rsl');
		my $abis = $lapd{$ci}{$id}{"ABIS_TOPOLOGY"};
		my $count = 0;
		while ($abis =~ /(chain|ring)/g) {
			if ($abis =~ /ring/) {
				$count += 2;
			}
			else {
				$count++;
			}
		}
		
		if (not exists($seenAbis{$omc}{$bsc}{$abis})) {
			$abisCount{$omc}{$bsc}{$lapd{$ci}{$id}{"TSU"}} += $count;
			$seenAbis{$omc}{$bsc}{$abis} = 1;
		}
		$cellCount{$omc}{$bsc}{$abis}{$ci} = 1;
		#print "$abis : $count\n";
	#	print "$rate : $abis\n";
		$info{$omc}{$bsc}{$abis}{"BTS_NUM"} = 0 if not exists($info{$omc}{$bsc}{$abis}{"BTS_NUM"});
		$info{$omc}{$bsc}{$abis}{"BTS_NUM"} = $rank if ($rank > $info{$omc}{$bsc}{$abis}{"BTS_NUM"});
		$info{$omc}{$bsc}{$abis}{"RSL_FR"} = 0 if not exists($info{$omc}{$bsc}{$abis}{"RSL_FR"});
		$info{$omc}{$bsc}{$abis}{"RSL_DR"} = 0 if not exists($info{$omc}{$bsc}{$abis}{"RSL_DR"});
		$info{$omc}{$bsc}{$abis}{"RSL_FR"}++ if ($rate eq 'fullRate');
		$info{$omc}{$bsc}{$abis}{"RSL_DR"}++ if ($rate eq 'multiRate');
		$info{$omc}{$bsc}{$abis}{"CONFIG"} = $config;
		$info{$omc}{$bsc}{$abis}{"TS_FREE"} = $tsFree;
		my $tsu = $lapd{$ci}{$id}{"TSU"};
		$info{$omc}{$bsc}{$abis}{"TSU"} = $tsu;
		$info{$omc}{$bsc}{$abis}{"TCU_FREE"} = 0;
		$info{$omc}{$bsc}{$abis}{"FR_FREE"} = 0;
		foreach my $tcu (keys %{$RSL{$omc}{$bsc}{$tsu}}) {
			my $tcuLoad = $RSL{$omc}{$bsc}{$tsu}{$tcu}{"TCU_LOAD"};
			my $pUsable = $RSL{$omc}{$bsc}{$tsu}{$tcu}{"POOL_USABLE"};
			$info{$omc}{$bsc}{$abis}{"TCU_FREE"}++ if ($tcuLoad == 0);
			if ($pUsable eq 'YES') {
				my $frFree = 4 - 4*$tcuLoad;
				$info{$omc}{$bsc}{$abis}{"FR_FREE"} += $frFree;
			}
		}
	}
}

open(ABIS,">".$config{"OUTPUT_CSV"}."abisSummary.csv") || die "Cannot open ".$config{"OUTPUT_CSV"}."abisSummary.csv: $!\n";
print ABIS "BSC;CONFIG;ABIS_PORT;TSU;BTS_COUNT;CELL_COUNT;RSL_FR;RSL_DR;FREE_ABIS_TS;FREE_ABIS_PORTS;FREE_TCU;FREE_FR\n";
foreach my $omc (keys %info) {
	foreach my $bsc (keys %{$info{$omc}}) {
		foreach my $abis (sort keys %{$info{$omc}{$bsc}}) {
			my $rslFr = $info{$omc}{$bsc}{$abis}{"RSL_FR"};
			my $rslDr = $info{$omc}{$bsc}{$abis}{"RSL_DR"};
			my $tsFree = $info{$omc}{$bsc}{$abis}{"TS_FREE"};
			my $btsNum = $info{$omc}{$bsc}{$abis}{"BTS_NUM"};
			my $tsu = $info{$omc}{$bsc}{$abis}{"TSU"};
			
			my $config = $info{$omc}{$bsc}{$abis}{"CONFIG"};
			my $freeports = 6 - $abisCount{$omc}{$bsc}{$tsu};
			my $cellCount = keys %{$cellCount{$omc}{$bsc}{$abis}};
			my $freeTcu = $info{$omc}{$bsc}{$abis}{"TCU_FREE"};
			my $freeFr = $info{$omc}{$bsc}{$abis}{"FR_FREE"};
			print ABIS "$bsc;$config;$abis;$tsu;$btsNum;$cellCount;$rslFr;$rslDr;$tsFree;$freeports;$freeTcu;$freeFr\n";
		}
	}
}
close(ABIS);

__END__
