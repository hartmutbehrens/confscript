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

my %ttp = (
	"Alcatel2MbTTPInstanceIdentifier"	=>1,
	"AdministrativeState"	=>1,
	"AlignmentStatus" => 1,
	"TTPtype" => 1,
	"Mfs2MbTTP"	=>1
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
my %posn = ();
foreach my $omc (keys %rnlBsc) {
	foreach my $id (keys %{$rnlBsc{$omc}}) {		
		@{$mfsName{$omc}{$id}}{qw/MFS_NAME MFS_ID BSC_NAME/} = ($rnlMfs{$omc}{$rnlBsc{$omc}{$id}{'RnlRelatedMFS'}}{"UserLabel"},@{$rnlBsc{$omc}{$id}}{qw/RnlRelatedMFS UserLabel/});
	}
}

#print Dumper(\%mfsName);

loadACIE("Alcatel2MbTTP","eml",\%ttp);
my ($bsc,$ttpNum,$gpu,$rack,$subrack,$port);
foreach my $omc (keys %ttp) {
	foreach my $id (keys %{$ttp{$omc}}) {
		my $mfsttp = $ttp{$omc}{$id}{"Mfs2MbTTP"};
		next if ($mfsttp =~ /unknown\:NULL/i);
		($bsc) = ($id =~ /amecID\s(\d+)/);
		($ttpNum) = ($mfsttp =~ /ttp_number\s(\d+)/);
		$gpu = ($ttpNum/256) % 256;
		$rack = ($ttpNum/(256*256*256)) % 256;
		$subrack = ($ttpNum/(256*256)) % 256;
		print "$omc : $bsc : $rack : $subrack : $gpu\n";
		print "$mfsName{$omc}{$bsc}{'MFS_ID'}\n";
		$toBsc{$omc}{$mfsName{$omc}{$bsc}{'MFS_ID'}}{$rack}{$subrack}{$gpu} = $bsc;
		#$port = $ttpNum % 256;
		if ( ($ttp{$omc}{$id}{'AdministrativeState'} eq 'unlocked') && ($ttp{$omc}{$id}{'TTPtype'} eq 'atermux') ) {
			$mfsConfig{$omc}{$bsc}{'GPU'}{$gpu}++ ;
			$mfsConfig{$omc}{$bsc}{'TTP'}{$ttpNum}++;	
		}
		$posn{$omc}{$bsc}{$gpu} = 'R '.$rack.', SR '.$subrack;
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
print GPU "OMC_ID;MFS;MFS_ID;BSC;GPUS;ATERPS;NSEIS;NSVCS;MFSTTPS;Gb;R_SR\n";
foreach my $omc (sort keys %mfsConfig) {
	foreach my $bsc (sort keys %{$mfsConfig{$omc}}) {
		my @gpu = sort {$a <=> $b} keys %{$mfsConfig{$omc}{$bsc}{'GPU'}};
		my @aterps = @{$mfsConfig{$omc}{$bsc}{'GPU'}}{@gpu};
		my $r_sr = join(' / ',map('GPU '.$_.': '.$posn{$omc}{$bsc}{$_},@gpu));
		my @ttp = sort keys %{$mfsConfig{$omc}{$bsc}{'TTP'}};
		my @nse = sort {$a <=> $b} keys %{$mfsConfig{$omc}{$bsc}{'NSE'}};
		my @vcs = map($_.':'.join(',',keys %{$mfsConfig{$omc}{$bsc}{'NSE'}{$_}}),@nse);
		my @gb = map($mfsConfig{$omc}{$bsc}{'Gb'}{$_}.' x '.$_.'TS ('.($_*64).'kbit/s)',keys %{$mfsConfig{$omc}{$bsc}{'Gb'}});
		print GPU $omc.';'.join(';',@{$mfsName{$omc}{$bsc}}{qw/MFS_NAME MFS_ID BSC_NAME/}).';'.join(';',join(',',@gpu),join(',',@aterps),join(',',@nse),join(',',@vcs),join(',',@ttp),join(',',@gb),$r_sr)."\n";
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
