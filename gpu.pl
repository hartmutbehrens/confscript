#!/usr/bin/perl -w
#!c:/Perl/bin/Perl.exe -w

# 2004 by Hartmut Behrens (##)
# compile MFS GPU configuration information
use strict;
use warnings;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";

my %rnlBsc = (
	"RnlAlcatelBSCInstanceIdentifier"	=>1,				#only load these columns
	"RnlRelatedMFS"				=>1,
	"UserLabel"				=>1
	);
	
my %rnlMfs = (
	"RnlAlcatelMFSInstanceIdentifier"	=>1,				#only load these columns
	"UserLabel"				=>1
	);

#my %ttp = (
#	"Alcatel2MbTTPInstanceIdentifier"	=>1,
#	"AdministrativeState"	=>1,
#	"AlignmentStatus" => 1,
#	"TTPtype" => 1,
#	"Mfs2MbTTP"	=>1
#	);
my %ttp = (
	"AGprs2MbTTPInstanceIdentifier" => 1,
	"AGprsCrc4Status" => 1,
	"AGprsTsUsed" => 1,
	"AGprsRemoteEquipment" => 1
);
	
my %mlBearer = (
	"AGprsBearerChannelInstanceIdentifier" => 1,
);

my %mlNse = (
	"AGprsNseInstanceIdentifier" => 1,
	"AGprsRelatedBssFunction" => 1,
	"AGprsNsei" => 1
	);
	
my %mlNsvc = (
	"AGprsNsvcInstanceIdentifier" => 1,
);
	
print "--Compiling GPU Config Information--\n";
loadACIE("RnlAlcatelBSC","rnl",\%rnlBsc);
loadACIE("RnlAlcatelMFS","rnl",\%rnlMfs);
loadACIE("AGprsNse","ml",\%mlNse);
loadACIE("AGprsNsvc","ml",\%mlNsvc);
loadACIE("AGprsBearerChannel","ml",\%mlBearer);

my %mfsConfig = ();
my %mfsName = ();
my %nse_to_bsc = ();
my %toBsc = ();
foreach my $omc (keys %rnlBsc) {
	foreach my $id (keys %{$rnlBsc{$omc}}) {		
		@{$mfsName{$omc}{$id}}{qw/MFS_NAME MFS_ID BSC_NAME/} = ($rnlMfs{$omc}{$rnlBsc{$omc}{$id}{'RnlRelatedMFS'}}{"UserLabel"},@{$rnlBsc{$omc}{$id}}{qw/RnlRelatedMFS UserLabel/});
	}
}

#print Dumper(\%mfsName);

#loadACIE("Alcatel2MbTTP","eml",\%ttp);
loadACIE("AGprs2MbTTP","ml",\%ttp);
my ($bsc,$ttpNum,$gpu,$rack,$subrack,$port);
foreach my $omc (keys %ttp) {
	foreach my $id (keys %{$ttp{$omc}}) {
		next if $ttp{$omc}{$id}{'AGprsTsUsed'} eq '{}';
		my ($ttpNum) = ($id =~ /moiRdn\s(\d+)/);
		next if $ttp{$omc}{$id}{'AGprsRemoteEquipment'} =~ /sgsn/;
		($bsc) = ($ttp{$omc}{$id}{'AGprsRemoteEquipment'} =~ /bssFunctionId\s(\d+)/);
		
		$gpu = ($ttpNum/256) % 256;
		$rack = ($ttpNum/(256*256*256)) % 256;
		$subrack = ($ttpNum/(256*256)) % 256;
		print "$omc : $bsc : $rack : $subrack : $gpu\n";
		print "$mfsName{$omc}{$bsc}{'MFS_ID'}\n";
		$toBsc{$omc}{$mfsName{$omc}{$bsc}{'MFS_ID'}}{$rack}{$subrack}{$gpu} = $bsc;
		#$port = $ttpNum % 256;
		#if ( ($ttp{$omc}{$id}{'AdministrativeState'} eq 'unlocked') && ($ttp{$omc}{$id}{'TTPtype'} eq 'atermux') ) {
			$mfsConfig{$omc}{$bsc}{'GPU'}{join(',',$rack,$subrack,$gpu)}++ ;
			$mfsConfig{$omc}{$bsc}{'TTP'}{$ttpNum}++;	
		#}
	}
}

foreach my $omc (keys %mlBearer) {
	foreach my $id (keys %{$mlBearer{$omc}}) {
		my ($mfs,$ttp,$ts) = ($id =~ /(\d+).*?(\d+).*?(\d+)/);
		$gpu = ($ttp/256) % 256;
		$rack = ($ttp/(256*256*256)) % 256;
		$subrack = ($ttp/(256*256)) % 256;
		my $bsc = $toBsc{$omc}{$mfs}{$rack}{$subrack}{$gpu};
		next unless defined $bsc;
		$mfsConfig{$omc}{$bsc}{'Gb'}{$ts}++;
	}
}

foreach my $omc (keys %mlNse) {
	foreach my $id (keys %{$mlNse{$omc}}) {
		my ($bscId) = ($mlNse{$omc}{$id}{'AGprsRelatedBssFunction'} =~ /.*?(\d+)/);
		$nse_to_bsc{$omc}{$mlNse{$omc}{$id}{'AGprsNsei'}} = $bscId;
	}
}

foreach my $omc (keys %mlNsvc) {
	foreach my $id (keys %{$mlNsvc{$omc}}) {
		my ($nse,$nsvc) = ($id =~ /moiRdn\s(\d+).*?moiRdn\s(\d+)/);
		my $bscId = $nse_to_bsc{$omc}{$nse};
		$mfsConfig{$omc}{$bscId}{'NSE'}{$nse}{$nsvc}++;
	}
}

#spool GPU CSV output
open(GPU,">".$config{"OUTPUT_CSV"}."gpu.csv") || die "Cannot open gpu.csv: $!\n";
print GPU "OMC_ID;MFS;MFS_ID;BSC;GPUS;ATERPS;NSEIS;NSVCS;MFSTTPS;Gb\n";
foreach my $omc (sort keys %mfsConfig) {
	foreach my $bsc (sort keys %{$mfsConfig{$omc}}) {
		my @gpu = sort {$a cmp $b} keys %{$mfsConfig{$omc}{$bsc}{'GPU'}};
		my @aterps = @{$mfsConfig{$omc}{$bsc}{'GPU'}}{@gpu};
		@gpu = map((split(',',$_))[2],@gpu);
		
		my @ttp = sort keys %{$mfsConfig{$omc}{$bsc}{'TTP'}};
		my @nse = sort {$a <=> $b} keys %{$mfsConfig{$omc}{$bsc}{'NSE'}};
		my @vcs = map($_.':'.join(',',keys %{$mfsConfig{$omc}{$bsc}{'NSE'}{$_}}),@nse);
		my @gb = map($mfsConfig{$omc}{$bsc}{'Gb'}{$_}.' x '.$_.'TS ('.($_*64).'kbit/s)',keys %{$mfsConfig{$omc}{$bsc}{'Gb'}});
		print GPU $omc.';'.join(';',@{$mfsName{$omc}{$bsc}}{qw/MFS_NAME MFS_ID BSC_NAME/}).';'.join(';',join(',',@gpu),join(',',@aterps),join(',',@nse),join(',',@vcs),join(',',@ttp),join(',',@gb))."\n";
	}
}
close GPU || die "Cannot close gpu.csv: $!\n";
print "--END:Compiling GPU Config Information:END--\n";

sub getGbTs {
	my ($ts) = @_;
	my $rv = 0;
	$rv++ while ($ts =~ /\d+/g);
	return ($rv);
}

__END__
