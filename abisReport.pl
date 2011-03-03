#!/usr/bin/perl -w
# Author: H.Behrens,Alcatel South Africa; Date: 2003-08-04; Revision: 0,etc.

#This script provides a daily indication on the config sheets of how many 
#A-bis TP's exist for which alarm reporting is is disabled.


#pragmas used: strict,warnings
use strict;
use warnings;

use strict;
use warnings;

#constants
use constant CELL_NAME_SIZE => 15;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";


my %rnlBSC = (
	"RnlAlcatelBSCInstanceIdentifier"	=>1,
	"UserLabel"			=>1
	);
	
my %btsSite = (
		"AlcatelBtsSiteManagerInstanceIdentifier"	=>1,
		"UserLabel"					=>1,
		"RelatedSecondaryAbis"				=>1
		);

print "Compiling Abis Info\n";	
loadACIE("AlcatelBtsSiteManager","eml",\%btsSite);
my %exclude = ();
my %bts2Abis = ();
my %siteName = ();
foreach my $omc (keys %btsSite) {
	foreach my $id (keys %{$btsSite{$omc}}) {
		my ($bsc) = ($id =~ /amecID\s(\d+)/);
		my $abis2 = $btsSite{$omc}{$id}{'RelatedSecondaryAbis'};
		#print "Abis 2 is $abis2\n";
		if ($abis2 =~ /related/) {
			$abis2 =~ s/relatedObject\:(.*)/$1/;
			#print "Excluding $omc,$bsc : $abis2\n";
			$exclude{$omc}{$bsc}{$abis2} = 1;
			my ($bts) = ($id =~ /moiRdn\s(\d+)/);
			$bts2Abis{$omc}{$bsc}{$bts} = $abis2;
			$siteName{$omc}{$bsc}{$bts} = $btsSite{$omc}{$id}{'UserLabel'};
		}
	}
}

loadACIE("RnlAlcatelBSC","rnl",\%rnlBSC);

getAbisInfo();

#functions from here

sub getAbisInfo {
	my %abis = (
  		"AlcatelAbisChainRingInstanceIdentifier"	=>1,
  		"QmuxTSInfo"					=>1,
  		"AbisTopology"					=>1,
  		"TtpNumber"					=>1,
  		"AbisTtpNumberForARing"				=>1,
  		"UserLabel"					=>1,
  		"BtsList"					=>1,
  		"RelatedBscTp"					=>1
  		);
  	my %element = (
  		"AlcatelManagedElementInstanceIdentifier"	=>1,
  		"RelatedAbisChainRing"				=>1,
  		"SupportedByObjectList"				=>1,
  		"OperationalState"				=>1,
  		"EquipmentType"					=>1,
  		"UserLabel"					=>1
  		);
  	my %ttp = (
		"Alcatel2MbTTPInstanceIdentifier"	=>1,
		"AdministrativeState"			=>1,
		"OperationalState"			=>1,
		"AvailabilityStatus"			=>1,
		"TTPtype"				=>1,
		"TtpNumber"				=>1
		);
	
  my %abisReport = ();
	my %abisNoBts = ();
  	
  loadACIE("AlcatelAbisChainRing","eml",\%abis);
  loadACIE("Alcatel2MbTTP","eml",\%ttp);
  open(ABISNOBTS,">".$config{"OUTPUT_CSV"}."abis_noBTS.csv") || die "Cannot open abis_noBTS.csv: $!\n";
	print ABISNOBTS "OMC_ID;BSC_NAME;BSC_ABIS_TP_NUMBER;BSC_TP_STATE;ABIS_TYPE;\n";
  	foreach my $omc (keys %abis) {
  		foreach my $id (keys %{$abis{$omc}}) {
  			my $topology = $abis{$omc}{$id}{"AbisTopology"};
  			my $ttpRing = $abis{$omc}{$id}{"AbisTtpNumberForARing"};;
  			my $ttp = $abis{$omc}{$id}{"TtpNumber"};
  			my $label = $abis{$omc}{$id}{"UserLabel"};
  			if ($topology eq 'ring') {
  				($ttpRing) = ($ttpRing =~ /number:(\w+)/);
  				$abis{$omc}{$id}{"AbisTopology"} = $topology.":".$ttp."/".$ttpRing;
  			}
  			else {
  				$abis{$omc}{$id}{"AbisTopology"} = $topology.":".$ttp;
  			}
  			if ($label =~ /DXX/) {
  				$abis{$omc}{$id}{"DXX_FLAG"} = "DXX";
  			}
  			else {
  				$abis{$omc}{$id}{"DXX_FLAG"} = "NO_DXX";
  			}
  			$abis{$omc}{$id}{"QmuxTS"} = $abis{$omc}{$id}{"QmuxTSInfo"};
  			my ($bsc) = ($abis{$omc}{$id}{"RelatedBscTp"} =~ /amecID\s(\d+)/);
  			next if (exists($exclude{$omc}{$bsc}{$id}));
  			my $bscName = $rnlBSC{$omc}{$bsc}{"UserLabel"};
  			if ($abis{$omc}{$id}{"BtsList"} eq '{}') {
  				my $ttpId = "{ ameID { amecID ".$bsc.", moiRdn 1}, moiRdn ".$ttp."}";
  				my $ttpState = $ttp{$omc}{$ttpId}{"AdministrativeState"};
  				print ABISNOBTS "$omc;$bscName;$ttp;$ttpState;$topology\n";
  			}
  		}
	}
	close ABISNOBTS  || die "Cannot close abis_noBTS.csv: $!\n";
	loadACIE("AlcatelManagedElement","eml",\%element);
	
	open(ABISREP,">".$config{"OUTPUT_CSV"}."abisReport.csv") || die "Cannot open abisReport.csv: $!\n";
	print ABISREP "OMC_ID;BSC_ID;BSC_NAME;BTS_ID;SITE_NAME;BSC_ABIS_TP_NUMBER;BSC_TP_STATE;SITE_TP_1_STATE;SITE_TP_2_STATE;ABIS_TYPE;RANK\n";
	my ($bsc,$bts);
	foreach my $omc (keys %element) {
  	foreach my $id (keys %{$element{$omc}}) {
  		my $type = $element{$omc}{$id}{"EquipmentType"};
  		next if not($type =~ /bts/);
  		my $btsId = $element{$omc}{$id}{"SupportedByObjectList"};
  		($bsc) = ($btsId =~ /amecID\s(\d+)/);
  		($bts) = ($btsId =~ /moiRdn\s(\d+)/);
  		my $relatedAbis = $element{$omc}{$id}{"RelatedAbisChainRing"};
  		($relatedAbis) = ($relatedAbis =~ /relatedObject\:(.*)/);
  		my $rank = get_rank($abis{$omc}{$relatedAbis}{'BtsList'},$id);
  		my $bscTp = $abis{$omc}{$relatedAbis}{"TtpNumber"};
  		my $site = $element{$omc}{$id}{"UserLabel"};
  		$site =~ s/\"//g;
  		my $topo = $abis{$omc}{$relatedAbis}{"AbisTopology"};
  		my $ttpId = "{ ameID { amecID ".$bsc.", moiRdn 1}, moiRdn ".$bscTp."}";
  		my $site1ttpId = "{ ameID ".$id.", moiRdn 1}";
  		my $site2ttpId = "{ ameID ".$id.", moiRdn 2}";
  		my $bscTpState = $ttp{$omc}{$ttpId}{"AdministrativeState"};
  		my $siteTp1State = join(' / ',@{$ttp{$omc}{$site1ttpId}}{qw/AdministrativeState OperationalState AvailabilityStatus/});
  		my $siteTp2State = join(' / ',@{$ttp{$omc}{$site2ttpId}}{qw/AdministrativeState OperationalState AvailabilityStatus/});
  		my $bscName = $rnlBSC{$omc}{$bsc}{"UserLabel"} || "NO_RNL_BSC_".$bsc;
  		$bscName =~ s/\"//g;
  		print ABISREP "$omc;$bsc;$bscName;$bts;$site;$bscTp;$bscTpState;$siteTp1State;$siteTp2State;$topo;$rank\n";
  		#print "$omc;$bsc;$bscName;$bts;$site;$bscTp;$bscTpState;$siteTp1State;$siteTp2State;$topo;$rank\n";
  	}
  }
  close ABISREP || die "Cannot close abisReport.csv: $!\n";
  open(ABISREP,">".$config{"OUTPUT_CSV"}."abisReport2.csv") || die "Cannot open abisReport2.csv: $!\n";
	print ABISREP "OMC_ID;BSC_ID;BSC_NAME;BTS_ID;SITE_NAME;BSC_2NDABIS_TP_NUMBER;BSC_TP_STATE;\n";
  foreach my $omc (keys %bts2Abis) {
  	foreach my $bsc (keys %{$bts2Abis{$omc}}) {
  		foreach my $bts (keys %{$bts2Abis{$omc}{$bsc}}) {
  			my $relatedAbis = $bts2Abis{$omc}{$bsc}{$bts};
  			my $bscTp = $abis{$omc}{$relatedAbis}{"TtpNumber"};
  			my $ttpId = "{ ameID { amecID ".$bsc.", moiRdn 1}, moiRdn ".$bscTp."}";
  			my $bscTpState = $ttp{$omc}{$ttpId}{"AdministrativeState"};
  			my $bscName = $rnlBSC{$omc}{$bsc}{"UserLabel"} || "NO_RNL_BSC_".$bsc;
  			my $siteName = $siteName{$omc}{$bsc}{$bts};
  			$bscName =~ s/\"//g;
  			$siteName =~ s/\"//g;
  			#print "$bscName : $siteName : $bscTp : $bscTpState\n";
  			print ABISREP "$omc;$bsc;$bscName;$bts;$siteName;$bscTp;$bscTpState;\n";
  		}
  	}
  }
  close ABISREP || die "Cannot close abisReport2.csv: $!\n";
	print "END: Compiling Abis Info\n";
}


sub get_rank {
	my ($btslist,$bts) = @_;
	my $rank = 0;
	while ($btslist =~ /(relatedObject.*?})/g) {
		$rank++;
		last if ('relatedObject:'.$bts eq $1);
	}
	return $rank;
}


1;
__END__
