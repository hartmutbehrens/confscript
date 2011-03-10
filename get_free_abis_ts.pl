#!/usr/local/bin/perl -w

# 2011 by Hartmut Behrens (##)
# calculate the amount of free Abis TS

use strict;
use warnings;
use Data::Dumper;

require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
require "loadACIEsubs.pl";


my %rbsc;
my %site;
my %bts_to_abis;
my %abis;
my %abiscr;

loadACIE("RnlAlcatelBSC","rnl",\%rbsc);

loadACIE("AlcatelBtsSiteManager","eml",\%site);
loadACIE("AlcatelAbisChainRing","eml",\%abiscr);

get_abis_mapping();

for my $omc (keys %site) {
	for my $id (keys %{$site{$omc}}) {
		
		my ($bsc,$bts) = ($id =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
		my $bsc_name = $rbsc{$omc}{$bsc}{'UserLabel'};
		s/\"//g for $bsc_name;
		my ($abis1,$abis2) = ($site{$omc}{$id}{'AbisID'} // $bts_to_abis{$omc}{$bsc}{$bts},undef);
		next unless $abis1;
		
		my @tre = map(get_tre($_,$site{$omc}{$id}{'SectorAndTreInfo'}), qw/numberOfGsm900Tre numberOfGsm1800Gsm1900Tre numberOfDRGsm900Tre numberOfDRGsm1800Gsm1900Tre/);
		
		my $fr_tre = $tre[0] + $tre[1] - ($tre[2] + $tre[3]);
		my $dr_tre = $tre[2] + $tre[3];
		
		 
		my $name1 = join(':',@{$abiscr{$omc}{'{ amecID '.$bsc.', moiRdn '.$abis1.'}'}}{qw(AbisTopology TtpNumber)}) // '';
		
		$abis{$bsc_name}{$name1}{'usable'} = get_usable_ts($site{$omc}{$id}{'UsableTSs'});
		$abis{$bsc_name}{$name1}{'fr_tre'} += $fr_tre;
		$abis{$bsc_name}{$name1}{'dr_tre'} += $dr_tre;
		$abis{$bsc_name}{$name1}{'om'} = 1;
		
		($abis2) = ($site{$omc}{$id}{'RelatedSecondaryAbis'} =~ /moiRdn\s(\d+)/) if $site{$omc}{$id}{'RelatedSecondaryAbis'} =~ /related/;
		if ($abis2) {
			my $name2 = join(':',@{$abiscr{$omc}{'{ amecID '.$bsc.', moiRdn '.$abis2.'}'}}{qw(AbisTopology TtpNumber)});
			$abis{$bsc_name}{$name2}{'extra_ts'} += $site{$omc}{$id}{'NExtraAbisTs'};	
		}
		else {
			$abis{$bsc_name}{$name1}{'extra_ts'} += $site{$omc}{$id}{'NExtraAbisTs'};
		}
		
	}
}

open my $file,">",$href->{'OUTPUT_CSV'}.'free_abis_ts.csv' || die "Cannot open free_abis_ts.csv.csv: $!\n";
print $file join(';', qw(BSC ABIS USABLE_TS FR_TRE DR_TRE EXTRA_ABIS_TS OM ABIS_TRAFFIC_TS ESTIMATED_SIG_TS FREE_TS) ),"\n";
for my $bsc (keys %abis) {
	for my $abis (keys %{$abis{$bsc}}) {
		my $usable = $abis{$bsc}{$abis}{'usable'} // 32;
		my $fr_tre = $abis{$bsc}{$abis}{'fr_tre'} // 0;
		my $dr_tre = $abis{$bsc}{$abis}{'dr_tre'} // 0;
		my $extra_ts = $abis{$bsc}{$abis}{'extra_ts'} // 0;
		my $om = $abis{$bsc}{$abis}{'om'} // 0;
		my $traffic_ts = 2*( $fr_tre + $dr_tre ) // 0;
		my $sig_ts = int( ( $fr_tre + $dr_tre )/4 ) // 0; 
		$abis{$bsc}{$abis}{'free_ts'} = $usable - $extra_ts - $om - $traffic_ts - $sig_ts;
		$abis{$bsc}{$abis}{'free_ts'} = 0 if ($abis{$bsc}{$abis}{'free_ts'} < 0 );
		print $file join(';',($bsc,$abis,$usable,$fr_tre,$dr_tre,$extra_ts,$om,$traffic_ts,$sig_ts,$abis{$bsc}{$abis}{'free_ts'})),"\n";
	}
}
close $file;

sub get_abis_mapping {
	for my $omc (keys %abiscr) {
		for my $abis (keys %{$abiscr{$omc}}) {
			next if $abiscr{$omc}{$abis}{'BtsList'} eq '{}'; 
			my ($id) = ($abis =~ /moiRdn\s(\d+)/);
			my ($first_bsc,$first_bts) = ($abiscr{$omc}{$abis}{'BtsList'} =~ /.*?amecID\s(\d+).*?moiRdn\s(\d+)/);
			$bts_to_abis{$omc}{$first_bsc}{$first_bts} = $id;
		}
	}
}

sub get_usable_ts {
	my $val = shift;
	my $total = 0;
	$total++ while $val =~ /\d+/g;
	return $total;
}

sub get_tre {
	my ($which,$val) = @_;
	my $total = 0;
	while ($val =~ /$which\s(\d+)/g) {
		$total += $1;
	}
	return $total;
}


