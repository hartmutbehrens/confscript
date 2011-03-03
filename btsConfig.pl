#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# Compile BTS configuration info
use strict;
#use warnings;
use Data::Dumper;

#constants
use constant CELL_NAME_SIZE => 18;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";


#variables
my %radioTypes = ();

my @G2TCUArray = ();
my %sector = ();
my %abisInfo = ();

#===============================RACK1================================
#[][RACK][SHELF][SLOT]
#Rack 1, Shelf 7
#TSU 1
$G2TCUArray[0][1][7][29] = 1;
$G2TCUArray[0][1][7][31] = 2;
$G2TCUArray[0][1][7][33] = 3;
$G2TCUArray[0][1][7][35] = 4;
$G2TCUArray[0][1][7][37] = 5;
$G2TCUArray[0][1][7][39] = 6;
$G2TCUArray[0][1][7][41] = 7;
$G2TCUArray[0][1][7][43] = 8;
$G2TCUArray[1][1][7][29] = 1;
$G2TCUArray[1][1][7][31] = 1;
$G2TCUArray[1][1][7][33] = 1;
$G2TCUArray[1][1][7][35] = 1;
$G2TCUArray[1][1][7][37] = 1;
$G2TCUArray[1][1][7][39] = 1;
$G2TCUArray[1][1][7][41] = 1;
$G2TCUArray[1][1][7][43] = 1;
    
#Rack 1, Shelf 4
#TSU 2
$G2TCUArray[0][1][4][9] = 9;
$G2TCUArray[0][1][4][11] = 10;
$G2TCUArray[0][1][4][13] = 11;
$G2TCUArray[0][1][4][15] = 12;
$G2TCUArray[0][1][4][17] = 13;
$G2TCUArray[0][1][4][19] = 14;
$G2TCUArray[0][1][4][21] = 15;
$G2TCUArray[0][1][4][23] = 16;
$G2TCUArray[1][1][4][9] = 2;
$G2TCUArray[1][1][4][11] = 2;
$G2TCUArray[1][1][4][13] = 2;
$G2TCUArray[1][1][4][15] = 2;
$G2TCUArray[1][1][4][17] = 2;
$G2TCUArray[1][1][4][19] = 2;
$G2TCUArray[1][1][4][21] = 2;
$G2TCUArray[1][1][4][23] = 2;
#TSU 3;
$G2TCUArray[0][1][4][41] = 17;
$G2TCUArray[0][1][4][43] = 18;
$G2TCUArray[0][1][4][45] = 19;
$G2TCUArray[0][1][4][47] = 20;
$G2TCUArray[0][1][4][49] = 21;
$G2TCUArray[0][1][4][51] = 22;
$G2TCUArray[0][1][4][53] = 23;
$G2TCUArray[0][1][4][55] = 24;
$G2TCUArray[1][1][4][41] = 3;
$G2TCUArray[1][1][4][43] = 3;
$G2TCUArray[1][1][4][45] = 3;
$G2TCUArray[1][1][4][47] = 3;
$G2TCUArray[1][1][4][49] = 3;
$G2TCUArray[1][1][4][51] = 3;
$G2TCUArray[1][1][4][53] = 3;
$G2TCUArray[1][1][4][55] = 3;
    
#Rack1 , Shelf3
#TSU 4
$G2TCUArray[0][1][3][45] = 25;
$G2TCUArray[0][1][3][47] = 26;
$G2TCUArray[0][1][3][49] = 27;
$G2TCUArray[0][1][3][51] = 28;
$G2TCUArray[0][1][3][53] = 29;
$G2TCUArray[0][1][3][55] = 30;
$G2TCUArray[0][1][3][57] = 31;
$G2TCUArray[0][1][3][59] = 32;
$G2TCUArray[1][1][3][45] = 4;
$G2TCUArray[1][1][3][47] = 4;
$G2TCUArray[1][1][3][49] = 4;
$G2TCUArray[1][1][3][51] = 4;
$G2TCUArray[1][1][3][53] = 4;
$G2TCUArray[1][1][3][55] = 4;
$G2TCUArray[1][1][3][57] = 4;
$G2TCUArray[1][1][3][59] = 4;
    
#===============================RACK2================================
#Rack2 , Shelf8
#TSU 5
$G2TCUArray[0][2][8][17] = 33;
$G2TCUArray[0][2][8][19] = 34;
$G2TCUArray[0][2][8][21] = 35;
$G2TCUArray[0][2][8][25] = 36;
$G2TCUArray[0][2][8][29] = 37;
$G2TCUArray[0][2][8][31] = 38;
$G2TCUArray[0][2][8][33] = 39;
$G2TCUArray[0][2][8][35] = 40;
$G2TCUArray[1][2][8][17] = 5;
$G2TCUArray[1][2][8][19] = 5;
$G2TCUArray[1][2][8][21] = 5;
$G2TCUArray[1][2][8][25] = 5;
$G2TCUArray[1][2][8][29] = 5;
$G2TCUArray[1][2][8][31] = 5;
$G2TCUArray[1][2][8][33] = 5;
$G2TCUArray[1][2][8][35] = 5;
    
#Rack2 , Shelf7
#TSU 6
$G2TCUArray[0][2][7][29] = 41;
$G2TCUArray[0][2][7][31] = 42;
$G2TCUArray[0][2][7][33] = 43;
$G2TCUArray[0][2][7][35] = 44;
$G2TCUArray[0][2][7][37] = 45;
$G2TCUArray[0][2][7][39] = 46;
$G2TCUArray[0][2][7][41] = 47;
$G2TCUArray[0][2][7][43] = 48;
$G2TCUArray[1][2][7][29] = 6;
$G2TCUArray[1][2][7][31] = 6;
$G2TCUArray[1][2][7][33] = 6;
$G2TCUArray[1][2][7][35] = 6;
$G2TCUArray[1][2][7][37] = 6;
$G2TCUArray[1][2][7][39] = 6;
$G2TCUArray[1][2][7][41] = 6;
$G2TCUArray[1][2][7][43] = 6;

#Rack 2, Shelf 4
#TSU 7
$G2TCUArray[0][2][4][9] = 49;
$G2TCUArray[0][2][4][11] = 50;
$G2TCUArray[0][2][4][13] = 51;
$G2TCUArray[0][2][4][15] = 52;
$G2TCUArray[0][2][4][17] = 53;
$G2TCUArray[0][2][4][19] = 54;
$G2TCUArray[0][2][4][21] = 55;
$G2TCUArray[0][2][4][23] = 56;
$G2TCUArray[1][2][4][9] = 7;
$G2TCUArray[1][2][4][11] = 7;
$G2TCUArray[1][2][4][13] = 7;
$G2TCUArray[1][2][4][15] = 7;
$G2TCUArray[1][2][4][17] = 7;
$G2TCUArray[1][2][4][19] = 7;
$G2TCUArray[1][2][4][21] = 7;
$G2TCUArray[1][2][4][23] = 7;
#TSU 8
$G2TCUArray[0][2][4][41] = 57;
$G2TCUArray[0][2][4][43] = 58;
$G2TCUArray[0][2][4][45] = 59;
$G2TCUArray[0][2][4][47] = 60;
$G2TCUArray[0][2][4][49] = 61;
$G2TCUArray[0][2][4][51] = 62;
$G2TCUArray[0][2][4][53] = 63;
$G2TCUArray[0][2][4][55] = 64;
$G2TCUArray[1][2][4][41] = 8;
$G2TCUArray[1][2][4][43] = 8;
$G2TCUArray[1][2][4][45] = 8;
$G2TCUArray[1][2][4][47] = 8;
$G2TCUArray[1][2][4][49] = 8;
$G2TCUArray[1][2][4][51] = 8;
$G2TCUArray[1][2][4][53] = 8;
$G2TCUArray[1][2][4][55] = 8;
    
#Rack2 , Shelf3
#TSU 9
$G2TCUArray[0][2][3][45] = 65;
$G2TCUArray[0][2][3][47] = 66;
$G2TCUArray[0][2][3][49] = 67;
$G2TCUArray[0][2][3][51] = 68;
$G2TCUArray[0][2][3][53] = 69;
$G2TCUArray[0][2][3][55] = 70;
$G2TCUArray[0][2][3][57] = 71;
$G2TCUArray[0][2][3][59] = 72;
$G2TCUArray[1][2][3][45] = 9;
$G2TCUArray[1][2][3][47] = 9;
$G2TCUArray[1][2][3][49] = 9;
$G2TCUArray[1][2][3][51] = 9;
$G2TCUArray[1][2][3][53] = 9;
$G2TCUArray[1][2][3][55] = 9;
$G2TCUArray[1][2][3][57] = 9;
$G2TCUArray[1][2][3][59] = 9;

#===============================RACK3================================
#Rack3 , Shelf8
#TSU10
$G2TCUArray[0][3][8][17] = 73;
$G2TCUArray[0][3][8][19] = 74;
$G2TCUArray[0][3][8][21] = 75;
$G2TCUArray[0][3][8][25] = 76;
$G2TCUArray[0][3][8][29] = 77;
$G2TCUArray[0][3][8][31] = 78;
$G2TCUArray[0][3][8][33] = 79;
$G2TCUArray[0][3][8][35] = 80;
$G2TCUArray[1][3][8][17] = 10;
$G2TCUArray[1][3][8][19] = 10;
$G2TCUArray[1][3][8][21] = 10;
$G2TCUArray[1][3][8][25] = 10;
$G2TCUArray[1][3][8][29] = 10;
$G2TCUArray[1][3][8][31] = 10;
$G2TCUArray[1][3][8][33] = 10;
$G2TCUArray[1][3][8][35] = 10;


#Rack3 , Shelf7
#TSU11
$G2TCUArray[0][3][7][29] = 81;
$G2TCUArray[0][3][7][31] = 82;
$G2TCUArray[0][3][7][33] = 83;
$G2TCUArray[0][3][7][35] = 84;
$G2TCUArray[0][3][7][37] = 85;
$G2TCUArray[0][3][7][39] = 86;
$G2TCUArray[0][3][7][41] = 87;
$G2TCUArray[0][3][7][43] = 88;
$G2TCUArray[1][3][7][29] = 11;
$G2TCUArray[1][3][7][31] = 11;
$G2TCUArray[1][3][7][33] = 11;
$G2TCUArray[1][3][7][35] = 11;
$G2TCUArray[1][3][7][37] = 11;
$G2TCUArray[1][3][7][39] = 11;
$G2TCUArray[1][3][7][41] = 11;
$G2TCUArray[1][3][7][43] = 11;


#Rack3 , Shelf4
#TSU12
$G2TCUArray[0][3][4][9] = 89;
$G2TCUArray[0][3][4][11] = 90;
$G2TCUArray[0][3][4][13] = 91;
$G2TCUArray[0][3][4][15] = 92;
$G2TCUArray[0][3][4][17] = 93;
$G2TCUArray[0][3][4][19] = 94;
$G2TCUArray[0][3][4][21] = 95;
$G2TCUArray[0][3][4][23] = 96;
$G2TCUArray[1][3][4][9] = 12;
$G2TCUArray[1][3][4][11] = 12;
$G2TCUArray[1][3][4][13] = 12;
$G2TCUArray[1][3][4][15] = 12;
$G2TCUArray[1][3][4][17] = 12;
$G2TCUArray[1][3][4][19] = 12;
$G2TCUArray[1][3][4][21] = 12;
$G2TCUArray[1][3][4][23] = 12;

#Rack3 , Shelf4
#TSU13
$G2TCUArray[0][3][4][41] = 97;
$G2TCUArray[0][3][4][43] = 98;
$G2TCUArray[0][3][4][45] = 99;
$G2TCUArray[0][3][4][47] = 100;
$G2TCUArray[0][3][4][49] = 101;
$G2TCUArray[0][3][4][51] = 102;
$G2TCUArray[0][3][4][53] = 103;
$G2TCUArray[0][3][4][55] = 104;
$G2TCUArray[1][3][4][41] = 13;
$G2TCUArray[1][3][4][43] = 13;
$G2TCUArray[1][3][4][45] = 13;
$G2TCUArray[1][3][4][47] = 13;
$G2TCUArray[1][3][4][49] = 13;
$G2TCUArray[1][3][4][51] = 13;
$G2TCUArray[1][3][4][53] = 13;
$G2TCUArray[1][3][4][55] = 13;

#Rack3 , Shelf 3
#TSU14
$G2TCUArray[0][3][3][45] = 105;
$G2TCUArray[0][3][3][47] = 106;
$G2TCUArray[0][3][3][49] = 107;
$G2TCUArray[0][3][3][51] = 108;
$G2TCUArray[0][3][3][53] = 109;
$G2TCUArray[0][3][3][55] = 110;
$G2TCUArray[0][3][3][57] = 111;
$G2TCUArray[0][3][3][59] = 112;
$G2TCUArray[1][3][3][45] = 14;
$G2TCUArray[1][3][3][47] = 14;
$G2TCUArray[1][3][3][49] = 14;
$G2TCUArray[1][3][3][51] = 14;
$G2TCUArray[1][3][3][53] = 14;
$G2TCUArray[1][3][3][55] = 14;
$G2TCUArray[1][3][3][57] = 14;
$G2TCUArray[1][3][3][59] = 14;

#G2 BSC connectivity limits
my %g2Tcu = (
	'config1'	=>	8,
	'config2'	=>	32,
	'config3'	=>	48,
	'config4'	=>	72,
	'config5'	=>	88,
	'config6'	=>	112
);
my %g2Abis = (
	'config1'	=>	6,
	'config2'	=>	24,
	'config3'	=>	36,
	'config4'	=>	54,
	'config5'	=>	66,
	'config6'	=>	84
);


my %freeCap = ();
my %frCap = ();
my %abisCap = ();
my %abis2Cap = ();
my %siteToTSU = ();
my $secabisToTSU = ();
my %bscConfig = ();
my @bscCols = qw /GEN CONFIG CS_HWAY_NO CS_HWAY_NO(LOCKED) N7_NO PS_HWAY_NO GSL_NO MFS_ID MFS_NAME MFS_GEN/;

print "--Compiling BTS Config Information--\n";
my %rnlBSC = (
	"RnlAlcatelBSCInstanceIdentifier"	=>1,
	"En4DrTrePerTcu" => 1,
	"UserLabel"			=>1
	);
loadACIE("RnlAlcatelBSC","rnl",\%rnlBSC);
my %circuit = (
		"AlcatelCircuitPackInstanceIdentifier"	=>1,			#only load these columns
		"ActiveStandbyMode" => 1,
		"BtsSector"				=>1,
		"CircuitPackType"			=>1,
		"SupportedByObjectList"			=>1
		);
loadACIE("AlcatelCircuitPack","eml",\%circuit);

getSectorInfo();
getAbisInfo();
getRadioInfo();
getLapdLinkInfo();
#spool BTS Config CSV output
my @btsColms = qw/SITE_NAME BTS_GENERATION uBTS QMuxAddress PowerLevel MuxRule AdministrativeState OperationalState AbisTopology 2ndAbis SynchBts QmuxTS RANK DXX_FLAG FE_AMP CONTROL FrameUnit Abis_TS_Free 2ndAbis_TS_Free TotalExtraTs/;
my @celColms = qw/CELL_NAME LAC CI SECTOR TRX_NUM TRA_EQUIPPED TRA_AMOUNT TRE_AMOUNT BCCHFrequency SECTOR_RSL_NUM ANX ANX_COUNT ANY ANY_COUNT ANC ANC_COUNT Availability MaxEgprsMcs ExtaAbisTs AGprsMinPdch AGprsMaxPdchHighLoad AGprsMaxPdch Radio_Type/;

my %btsData = ();
my %celData = ();
my @radios = sort keys %radioTypes;

#save site to TSU mapping (might be useful for some other applications
open(STT,">".$config{"OUTPUT_CSV"}."siteToTSU.csv") || die "Cannot open siteToTSU.csv: $!\n";
print STT "OMC;BSC_ID;BTS_ID;PrimaryAbisTSU;SecondaryAbisTSU\n";
foreach my $omc (keys %siteToTSU) {
	foreach my $bsc (keys %{$siteToTSU{$omc}}) {
		foreach my $bts (keys %{$siteToTSU{$omc}{$bsc}}) {
			my ($pri,$sec) = @{$siteToTSU{$omc}{$bsc}{$bts}}{qw/Prim Sec/};
			print STT "$omc;$bsc;$bts;$pri;$sec\n";
		}
	}
}
close(STT);

open(BTS,">".$config{"OUTPUT_CSV"}."btsConfig.csv") || die "Cannot open btsConfig.csv: $!\n";
print BTS "OMC;BSC_ID;BSC_NAME;".join(';',@bscCols).";BTS_ID;".join(';',@btsColms).";".join(';',@celColms).";".join(';',@radios)."\n";
my $count = 0;
foreach my $omc (keys %sector) {
	foreach my $bsc (keys %{$sector{$omc}}) {
		my $bscName = $rnlBSC{$omc}{$bsc}{"UserLabel"} || "NO_RNL_BSC_".$bsc;
		foreach my $bts (keys %{$sector{$omc}{$bsc}}) {
			my $frameUnit = undef;
			$frameUnit .= $sector{$omc}{$bsc}{$bts}{"\"fumo\""}."-fumo" if (exists($sector{$omc}{$bsc}{$bts}{"\"fumo\""}));
			$frameUnit .= $sector{$omc}{$bsc}{$bts}{"\"fuco\""}."-fuco" if (exists($sector{$omc}{$bsc}{$bts}{"\"fuco\""}));
			$frameUnit .= $sector{$omc}{$bsc}{$bts}{"\"drfu\""}."-drfu" if (exists($sector{$omc}{$bsc}{$bts}{"\"drfu\""}));
			$sector{$omc}{$bsc}{$bts}{'FrameUnit'} = $frameUnit if defined($frameUnit);
			
			for (@btsColms) {
				$btsData{$_} = '-';
				$btsData{$_} = $sector{$omc}{$bsc}{$bts}{$_} if (exists($sector{$omc}{$bsc}{$bts}{$_}));
			}
			$btsData{'QMuxAddress'} =~ s/number\:(\d+)/$1/;
			$abisCap{$omc}{$bsc}{$bts}++ if ($btsData{'QmuxTS'} ne 'noQmux');
			
			my $tsUsed = $abisCap{$omc}{$bsc}{$bts};
			#print "TSUSED $tsUsed\n" if ($bts ==12);
			my $abisTsFree = int(31 - $tsUsed); 					#1TS not usable on Abis
			$abisTsFree = 0 if ($abisTsFree < 0);
			my $abis2Free = 'N/A';
			
			if ($btsData{'2ndAbis'} =~ /related/i) {
				my $ts2Used = ($abis2Cap{$omc}{$bsc}{$bts}||0);
				#print "$omc $bsc $bts ",$btsData{'2ndAbis'}," $ts2Used\n";
				$abis2Free = int(32 - $ts2Used); 	
			}
			
			($btsData{'Abis_TS_Free'},$btsData{'2ndAbis_TS_Free'}) = ($abisTsFree,$abis2Free);
			
			foreach my $sector (0..9) {
				next if not exists($sector{$omc}{$bsc}{$bts}{$sector});
				$sector{$omc}{$bsc}{$bts}{$sector}{'MaxEgprsMcs'}++;
				my $radioType = undef;
				foreach my $radio (sort keys %radioTypes) {
					$radio =~ s/\"//g;
					$radioTypes{$radio} = 0;
					if (exists($sector{$omc}{$bsc}{$bts}{$sector}{$radio})) {
						$radioTypes{$radio} = $sector{$omc}{$bsc}{$bts}{$sector}{$radio};
						$radioType .= $radioTypes{$radio}."-".$radio." ";
					}
				}
				$sector{$omc}{$bsc}{$bts}{$sector}{'Radio_Type'} = $radioType if defined($radioType);
				$sector{$omc}{$bsc}{$bts}{$sector}{'SECTOR'} = $sector;
				for (@celColms) {
					$celData{$_} = '-';
					$celData{$_} = $sector{$omc}{$bsc}{$bts}{$sector}{$_} if (exists($sector{$omc}{$bsc}{$bts}{$sector}{$_}));
				}
				print BTS "$omc;$bsc;$bscName;".join(';',@{$bscConfig{$omc}{$bsc}}{@bscCols}).";$bts;".join(';',@btsData{@btsColms}).";".join(';',@celData{@celColms}).";".join(';',@radioTypes{@radios})."\n";	
			}
		}
	}
}
close BTS || die "Cannot close btsConfig.csv: $!\n";
print "--END:Compiling BTS Config Information:END--\n";


## subroutines from here
sub getSectorInfo {
	my %bbtNum = (
		"AlcatelBasebandTransceiverInstanceIdentifier"	=>1
		);
	my %btsSector = ();
	my %rnlBsc = (
		"RnlAlcatelBSCInstanceIdentifier" => 1,
		"BSS_Release" => 1
		);
	my %btsSite = (
		"AlcatelBtsSiteManagerInstanceIdentifier"	=>1,
		"UserLabel"					=>1,
		"BTS_Generation"			=>1,
		"QMuxAddress"				=>1,
		"TxPowerLevel"				=>1,
		"MaxExtraTsPrimary"			=>1,
		"MuxRule"					=>1,
		"AdministrativeState"		=>1,
		"OperationalState"			=>1,
		"TrxTransmissionPoolsPerSector"	=>1,
		"RelatedSecondaryAbis"		=>1,
		"RelatedSynchronizedBTS"	=>1
		);
	my %cell = (
		"CellInstanceIdentifier"	=>1,
		"RnlSupportingSector"	=>1,
		"AGprsMaxEgprsMcs"		=>1,
		"AGprsMinPdch"			=>1,
		"AGprsMaxPdchHighLoad"	=>1,
		"AGprsMaxPdch"			=>1,
		"MaxGprsCs"				=>1,
		"UserLabel"				=>1
		);
	
	my %a = (
		'{}'	=> '-',
		'{1}'	=> 'failed',
		'{2}'	=> 'powerOff',
		'{3}'	=> 'offLine',
		'{4}'	=> 'offDuty',
		'{5}'	=> 'dependency',
		'{6}'	=> 'degraded',
		'{7}'	=> 'notInstalled',
		'{8}'	=> 'logFull',
		'{0}'	=> 'inTest'
	);
	
	print "Compiling BasebandTransciever count\n";
	loadACIE("AlcatelBasebandTransceiver","eml",\%bbtNum);
	my ($bsc,$bts,$sector,$lac,$ci);
	foreach my $omc (keys %bbtNum) {
		foreach my $id (keys %{$bbtNum{$omc}}) {
			($bsc,$bts,$sector) = ($id =~ /amecID\s(\d+).*?moiRdn\s(\d+).*?moiRdn\s(\d+)/);
			$sector{$omc}{$bsc}{$bts}{$sector}{"TRX_NUM"}++;
		}
	}
	print "END:Compiling BasebandTransciever count\n";
	print "Compiling BtsSite Info\n";
	print "Retriving GPRS & EGPRS Info\n";
	loadACIE("Cell","rnl",\%cell);
	foreach my $omc (keys %cell) {
		foreach my $id (keys %{$cell{$omc}}) {
			my $emlId = $cell{$omc}{$id}{"RnlSupportingSector"};
			my ($bsc,$bts,$sector) = ($emlId =~ /bsc\s(\d+).*?btsRdn\s(\d+).*?sectorRdn\s(\d+)/);
			@{$sector{$omc}{$bsc}{$bts}{$sector}}{qw/MaxEgprsMcs MaxGprsCs/} = ($cell{$omc}{$id}{"AGprsMaxEgprsMcs"},$cell{$omc}{$id}{"MaxGprsCs"});
			@{$sector{$omc}{$bsc}{$bts}{$sector}}{qw/AGprsMinPdch AGprsMaxPdchHighLoad AGprsMaxPdch/} = ($cell{$omc}{$id}{"AGprsMinPdch"},$cell{$omc}{$id}{"AGprsMaxPdchHighLoad"},$cell{$omc}{$id}{"AGprsMaxPdch"});
		}
	}
	print "END:Retriving GPRS & EGPRS Info\n";
	loadACIE("AlcatelBtsSiteManager","eml",\%btsSite);
	foreach my $omc (keys %btsSite) {
		foreach my $id (keys %{$btsSite{$omc}}) {
			($bsc,$bts) = ($id =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
			@{$sector{$omc}{$bsc}{$bts}}{qw/SITE_NAME BTS_GENERATION QMuxAddress/} = ($btsSite{$omc}{$id}{'UserLabel'},$btsSite{$omc}{$id}{'BTS_Generation'},$btsSite{$omc}{$id}{'QMuxAddress'});
			@{$sector{$omc}{$bsc}{$bts}}{qw/PowerLevel MuxRule AdministrativeState/} = ($btsSite{$omc}{$id}{'TxPowerLevel'},$btsSite{$omc}{$id}{'MuxRule'},$btsSite{$omc}{$id}{'AdministrativeState'});
			@{$sector{$omc}{$bsc}{$bts}}{qw/OperationalState TotalExtraTs SynchBts 2ndAbis MaxExtraTsPrimary/} = ($btsSite{$omc}{$id}{'OperationalState'},'0',$btsSite{$omc}{$id}{'RelatedSynchronizedBTS'},$btsSite{$omc}{$id}{'RelatedSecondaryAbis'},$btsSite{$omc}{$id}{'MaxExtraTsPrimary'});
			
			
		}
	}
	
	print "END:Compiling BtsSite Info\n";
	print "Compiling BtsSector Info\n";
	open(EDGE,">".$config{"OUTPUT_CSV"}."dataConfig.csv") || die "Cannot open dataConfig.csv: $!\n";
	print EDGE "OMC;BSC;BTS;LAC;CI;CELLNAME;GPRS;EDGE;EXTRAABISTS;MAXGPRSCS;MAXEGPRSMCS;TYPE2;TYPE3;TYPE4;TYPE5\n";
	loadACIE("RnlAlcatelBSC","rnl",\%rnlBsc);
	loadACIE("AlcatelBts_Sector","eml",\%btsSector);
	
	foreach my $omc (keys %btsSector) {
		foreach my $id (keys %{$btsSector{$omc}}) {
			($bsc,$bts,$sector) = ($id =~ /amecID\s(\d+).*?moiRdn\s(\d+).*?moiRdn\s(\d+)/);
			my $globalId = $btsSector{$omc}{$id}{"CellGlobalIdentity"};
			($lac,$ci) = ($globalId =~ /lac\s(\d+).*?ci\s(\d+)/);
			
			@{$sector{$omc}{$bsc}{$bts}{$sector}}{qw/LAC CI BCCHFrequency HR_ENABLED CELL_NAME Availability/} = ($lac,$ci,$btsSector{$omc}{$id}{"BCCHFrequency"},$btsSector{$omc}{$id}{"HR_ENABLED"},$btsSector{$omc}{$id}{"UserLabel"},$a{$btsSector{$omc}{$id}{"AvailabilityStatus"}});
			@{$sector{$omc}{$bsc}{$bts}{$sector}}{qw/SECTOR_RSL_NUM EnGprs EnEgprs ExtaAbisTs/} = ($btsSector{$omc}{$id}{"NbBaseBandTransceiver"},$btsSector{$omc}{$id}{"EnGprs"},$btsSector{$omc}{$id}{"EnEgprs"},$btsSector{$omc}{$id}{"ACmbNbExtraAbisTs"});
			#check if cell is split cell
			if ($sector{$omc}{$bsc}{$bts}{'SynchBts'} =~ /master/i) {
				my ($masterBts) = ($sector{$omc}{$bsc}{$bts}{'SynchBts'} =~ /moiRdn\s(\d+)/);
				my $masterId = "{ bsmID { amecID ".$bsc.", moiRdn ".$masterBts."}, moiRdn 1}";
				$sector{$omc}{$bsc}{$bts}{$sector}{"HR_ENABLED"} = $btsSector{$omc}{$masterId}{"HR_ENABLED"};
			}
			
			$sector{$omc}{$bsc}{$bts}{'TotalExtraTs'} = $btsSector{$omc}{$id}{"ACmbNExtraAbisTsMain"};
			
			my $edgeOn = $btsSector{$omc}{$id}{"EnEgprs"} eq 'TRUE' ? 'YES':'NO';
			my $gprsOn = $btsSector{$omc}{$id}{"EnGprs"} eq 'TRUE' ? 'YES':'NO';
			next if ($gprsOn eq 'NO');
			for (qw/MaxGprsCs MaxEgprsMcs ExtaAbisTs/) {
				$sector{$omc}{$bsc}{$bts}{$sector}{$_} = defined($sector{$omc}{$bsc}{$bts}{$sector}{$_}) ? $sector{$omc}{$bsc}{$bts}{$sector}{$_} : '0';
			}
			print EDGE "$omc;$bsc;$bts;$lac;$ci;".$btsSector{$omc}{$id}{"UserLabel"}.";$gprsOn".";$edgeOn;".$sector{$omc}{$bsc}{$bts}{$sector}{"ExtaAbisTs"}.";".$sector{$omc}{$bsc}{$bts}{$sector}{"MaxGprsCs"}.";".$sector{$omc}{$bsc}{$bts}{$sector}{"MaxEgprsMcs"}."\n";
		}
	}
	close EDGE  || die "Cannot close dataConfig.csv: $!\n";;
	print "END:Compiling BtsSector Info\n";
}



#NOTE : sdcchConfig.csv has to exist ! Therefore, sdcchConfig.pl has to be run prior to btsConfig.pl

sub getLapdLinkInfo {
	#load SDCCH info
	print "Retrieving SDCCH info\n";
	open(SDCCH,"<".$config{"OUTPUT_CSV"}."sdcchConfig.csv") || die "Cannot open sdcchConfig.csv: $!\n";
	my @cols;
	my %line = ();
	my %sdcch = ();
	while (<SDCCH>) {
		chomp;
		if ($. == 1) {				#load header line
			@cols = split(/;/,$_);
		}
		else {
			my @data = split(/;/,$_);
			@line{@cols} = @data;
			$sdcch{$line{"OMC_ID"}}{$line{"BSC"}}{$line{"BTS"}}{$line{"SECTOR"}}{$line{"TRX"}}{"NBR_SDCCH"} = $line{"NBR_SDCCH"};
			$sdcch{$line{"OMC_ID"}}{$line{"BSC"}}{$line{"BTS"}}{$line{"SECTOR"}}{$line{"TRX"}}{"DYNAMIC"} = $line{"DYNAMIC"};
		}
	}
	close(SDCCH) || die "Cannot close sdcchConfig.csv: $!\n";
	print "END: Retrieving SDCCH info\n";
	print "Retrieving BSC info\n";
  open(BSC,"<".$config{"OUTPUT_CSV"}."bscConfig.csv") || die "Cannot open bscConfig.csv: $!\n";
	while (<BSC>) {
		chomp;
		if ($. == 1) {				#load header line
			@cols = split(/;/,$_);
		}
		else {
			my @data = split(/;/,$_);
			@line{@cols} = @data;
			@{$bscConfig{$line{"OMC_ID"}}{$line{"BSC_ID"}}}{@cols} = @data;
		}
	}
	close(BSC) || die "Cannot close bscConfig.csv: $!\n";
	print "END: Retrieving BSC info\n";
	
	#retrieve basic LapD info
	my %lapd = (
		"AlcatelLapdLinkInstanceIdentifier"	=>1,
		"LapdLinkUsage"				=>1,
		"SpeechCodingRate"			=>1,
		"RelatedBtsSector"			=>1,
		"RelatedGSMEquipment"			=>1,
		"OperationalState"			=>1,
		"UserLabel"				=>1
		);
	loadACIE("AlcatelLapdLink","eml",\%lapd);
	my %btsSector = (
		"AlcatelBts_SectorInstanceIdentifier"	=>1,
		"CellGlobalIdentity"			=>1,
		"HR_ENABLED"				=>1,
		"UserLabel"				=>1
		);
		my %bSite = (
			"AlcatelBtsSiteManagerInstanceIdentifier" =>1,
			"UserLabel" =>1,
			);
	loadACIE("AlcatelBts_Sector","eml",\%btsSector);
	loadACIE("AlcatelBtsSiteManager","eml",\%bSite);
	my %completeLapd = ();
	my %ccpLoad = ();
	my %ccpBtsLoad = ();
	my %siteControl = ();
	foreach my $omc (keys %lapd) {
		foreach my $id (keys %{$lapd{$omc}}) {
			#next if ($lapd{$omc}{$id}{'OperationalState'} eq 'disabled');
			my ($bscid,$bts,$sector,$btssector,$trx,$rack,$shelf,$slot);
			my $label = $lapd{$omc}{$id}{"UserLabel"};
			if ($label =~ /RSL/) {
				($trx) = ($label =~ /RSL\s(\d+)/);
			}
			else {
				$trx = '';
			}
			next if ($label =~ /GSL/);
			($bscid) = ($id =~ /amecID\s(\d+)/);
			$completeLapd{$omc}{$id}{"BSC_ID"} = $bscid;
			my $equip = $lapd{$omc}{$id}{"RelatedGSMEquipment"};
			@{$completeLapd{$omc}{$id}}{qw/RelatedGSMEquipment OperationalState/} = ($equip,$lapd{$omc}{$id}{'OperationalState'});
			my $relSector = $lapd{$omc}{$id}{"RelatedBtsSector"};
			if ($relSector eq '{}') {
				$bts = "";$sector = "";$btssector = "";
				for (qw/SECTORNAME LAC CI ABIS_TOPOLOGY/) {
					$completeLapd{$omc}{$id}{$_} = '-';
				}
			}
			else {
				($bts,$sector) = ($relSector =~ /amecID.*?moiRdn\s(\d+).*?moiRdn\s(\d+)/);
				($btssector) = ($relSector =~ /\{(.*?)\}$/);
				my ($lac,$ci) = ($btsSector{$omc}{$btssector}{"CellGlobalIdentity"} =~ /lac\s(\d+).*?ci\s(\d+)/);
				@{$completeLapd{$omc}{$id}}{qw/SECTORNAME ABIS_TOPOLOGY LAC CI/} = ($btsSector{$omc}{$btssector}{"UserLabel"},$sector{$omc}{$bscid}{$bts}{'AbisTopology'},$lac,$ci);
			}
			if ($equip eq '{}') {
				($rack,$shelf,$slot) = ("","","");
				@{$completeLapd{$omc}{$id}}{qw/TCU TSU/} = ('-','-');
			}
			else {
				($rack,$shelf,$slot) = ($equip =~ /rackRdn\s(\d+).*?shelfRdn\s(\d+).*?moiRdn\s(\d+)/);
				my $siteId = join(';',$omc,$bscid,$bts);
				my $cId = join(',',$rack,$shelf,$slot);
				$siteControl{$siteId}{$cId}++;
				if ($bscConfig{$omc}{$bscid}{'GEN'} eq 'g2') {
					@{$completeLapd{$omc}{$id}}{qw/TCU TSU/} = ($G2TCUArray[0][$rack][$shelf][$slot],$G2TCUArray[1][$rack][$shelf][$slot]);
				}
				else {
					@{$completeLapd{$omc}{$id}}{qw/TCU TSU/} = ('-','-');
					my ($circuitId) = ($lapd{$omc}{$id}{'RelatedGSMEquipment'} =~ /^\{(.*)\}$/);
					my $bName = $bscConfig{$omc}{$bscid}{'NAME'};
					my $ccpId = join(';',$omc,$bscid,$bName,$rack,$shelf,$slot);
					my $siteId = '{ amecID '.$bscid.', moiRdn '.$bts.'}';
					my $btsName = $bSite{$omc}{$siteId}{'UserLabel'};
					if ($lapd{$omc}{$id}{'LapdLinkUsage'} eq 'rsl') {
						next unless $lapd{$omc}{$id}{'OperationalState'} eq 'enabled';
						my $bName = $bscConfig{$omc}{$bscid}{'NAME'};
						$ccpLoad{$ccpId}{'ActiveStandbyMode'} = $circuit{$omc}{$circuitId}{'ActiveStandbyMode'};
						$ccpLoad{$ccpId}{'FR_RSL'} += 1 if $lapd{$omc}{$id}{'SpeechCodingRate'} eq 'fullRate';
						$ccpLoad{$ccpId}{'DR_RSL'} += 1 if $lapd{$omc}{$id}{'SpeechCodingRate'} eq 'multiRate';
						$ccpBtsLoad{$ccpId}{$btsName}{'BSC_NAME'} = $bName;
						$ccpBtsLoad{$ccpId}{$btsName}{'FR_RSL'} = 0 if not exists $ccpBtsLoad{$ccpId}{$btsName}{'FR_RSL'};
						$ccpBtsLoad{$ccpId}{$btsName}{'DR_RSL'} = 0 if not exists $ccpBtsLoad{$ccpId}{$btsName}{'DR_RSL'};
						$ccpBtsLoad{$ccpId}{$btsName}{'FR_RSL'} += 1 if $lapd{$omc}{$id}{'SpeechCodingRate'} eq 'fullRate';
						$ccpBtsLoad{$ccpId}{$btsName}{'DR_RSL'} += 1 if $lapd{$omc}{$id}{'SpeechCodingRate'} eq 'multiRate';
						if ((defined $rnlBSC{$omc}{$bscid}{'En4DrTrePerTcu'}) && ($rnlBSC{$omc}{$bscid}{'En4DrTrePerTcu'} eq 'TRUE')) {
							$ccpLoad{$ccpId}{'EQ_FR'} = ($ccpLoad{$ccpId}{'FR_RSL'}||0) + ($ccpLoad{$ccpId}{'DR_RSL'}||0);
						}
						else {
							$ccpLoad{$ccpId}{'EQ_FR'} = ($ccpLoad{$ccpId}{'FR_RSL'}||0) + 2*($ccpLoad{$ccpId}{'DR_RSL'}||0);
						}
						
						$ccpLoad{$ccpId}{'FREE_RSL'} = 200 - $ccpLoad{$ccpId}{'EQ_FR'};
					}
				}
			}
			@{$completeLapd{$omc}{$id}}{qw/RACK SHELF SLOT/} = ($rack,$shelf,$slot);
			
			
			if (exists($sdcch{$omc}{$bscid}{$bts}{$sector}{$trx}{"NBR_SDCCH"})) {
				@{$completeLapd{$omc}{$id}}{qw/NBR_SDCCH DYNAMIC/} = @{$sdcch{$omc}{$bscid}{$bts}{$sector}{$trx}}{qw/NBR_SDCCH DYNAMIC/}
			}
			else {
				($completeLapd{$omc}{$id}{"NBR_SDCCH"},$completeLapd{$omc}{$id}{"DYNAMIC"}) = (0,0);
			}
			#print $completeLapd{$omc}{$id}{"SECTORNAME"},"TRX : $trx, SDCCH : ",$completeLapd{$omc}{$id}{"NBR_SDCCH"},"\n";
			for (qw/LapdLinkUsage SpeechCodingRate RelatedBtsSector RelatedGSMEquipment OperationalState UserLabel/) {
				$completeLapd{$omc}{$id}{$_} = $lapd{$omc}{$id}{$_};
			}
			$completeLapd{$omc}{$id}{"SITENAME"} = "";							#initialize
		}
	}
	#exit; - debugging
	#insert siteName Info into Lapd
	my %btsSite = (
		"AlcatelBtsSiteManagerInstanceIdentifier"	=>1,
		"UserLabel"					=>1,
		"RelatedOAMLapdLink"		=>1
		);
	loadACIE("AlcatelBtsSiteManager","eml",\%btsSite);
	my ($amecId);
	foreach my $omc (keys %btsSite) {
		foreach my $id (keys %{$btsSite{$omc}}) {
			my $oamlink = $btsSite{$omc}{$id}{"RelatedOAMLapdLink"};
			($amecId) = ($oamlink =~ /relatedObject\:(.*)/);
			$completeLapd{$omc}{$amecId}{"SITENAME"} = (exists($completeLapd{$omc}{$amecId})) ? $btsSite{$omc}{$id}{"UserLabel"} : '';
		}
	}
  #spool LAPD Info
  my @lapdCols = qw/LapdLinkUsage SpeechCodingRate UserLabel BSC_ID RACK SHELF SLOT TCU TSU SECTORNAME SITENAME LAC CI ABIS_TOPOLOGY NBR_SDCCH DYNAMIC/;
  open(LAPD,">".$config{"OUTPUT_CSV"}."lapdConfig.csv") || die "Cannot open lapdConfig.csv: $!\n";
  print LAPD "OMC_ID;AlcatelLapdLinkInstanceIdentifier;BSCNAME;".join(';',@lapdCols)."\n";
  foreach my $omc (keys %completeLapd) {
  	foreach my $id (keys %{$completeLapd{$omc}}) {
  		my $bscName = $bscConfig{$omc}{$completeLapd{$omc}{$id}{"BSC_ID"}}{'NAME'};
  		$bscName =~ s/\"//g;
  		print LAPD $omc.';'.$id.';'.$bscName.';'.join(';',@{$completeLapd{$omc}{$id}}{@lapdCols})."\n";
  	}
  }
  close(LAPD) || die "Cannot close lapdConfig.csv: $!\n";
  my @ccpCols = qw/ActiveStandbyMode FR_RSL DR_RSL EQ_FR FREE_RSL/;
  open(CCP,">".$config{"OUTPUT_CSV"}."ccpLoad.csv") || die "Cannat open ccpLoad.csv: $!\n";
  print CCP "OMC_ID;BSC_ID;BSC_NAME;RACK;SHELF;SLOT;".join(';',@ccpCols)."\n";
  foreach my $id (keys %ccpLoad) {
  	print CCP join(';',$id,@{$ccpLoad{$id}}{@ccpCols})."\n";
  }
  close(CCP);
  
  my @cbtsCol = qw(BSC_NAME FR_RSL DR_RSL);
  open(CCPBTS,">".$config{"OUTPUT_CSV"}."ccpBtsLoad.csv") || die "Cannat open ccpBtsLoad.csv: $!\n";
  print CCPBTS "OMC_ID;BSC_ID;RACK;SHELF;SLOT;BTSNAME;".join(';',@cbtsCol)."\n";
  foreach my $id (keys %ccpBtsLoad) {
  	foreach my $bts (keys  %{$ccpBtsLoad{$id}}) {
  		print CCPBTS join(';',$id,$bts,@{$ccpBtsLoad{$id}{$bts}}{@cbtsCol})."\n";
  	}
  }
  close(CCPBTS);
  
  open(SITEC,">".$config{"OUTPUT_CSV"}."siteControl.csv") || die "Cannat open ccpLoad.csv: $!\n";
  print SITEC "OMC_ID;BSC_ID;BTS_ID;CONTROL\n";
  foreach my $id (keys %siteControl) {
  	my $cntl = join(' / ',sort keys %{$siteControl{$id}});
  	print SITEC join(';',$id,$cntl)."\n";
  }
  close(SITEC);
  my %rslConfig = ();
  
	print "Compiling RSL Configuration (this takes a while)\n";
	  	
	open(RSLCONF,">".$config{"OUTPUT_CSV"}."rslConfig.csv") || die "Cannot open rslConfig.csv: $!\n";
	print RSLCONF "OMC_ID;BSC_ID;BSC_NAME;TSU;TCU;RSL_NO;FR_RSL_NO;DR_RSL_NO;OML_NO;RSL1;RATE1;RSL2;RATE2;RSL3;RATE3;RSL4;RATE4;OML1;OML2;SD_COUNT;TCU_LOAD;POOL_USABLE\n";
	  	
	open(HRP,">".$config{"OUTPUT_CSV"}."hrProblem.csv") || die "Cannot open hrProblem.csv: $!\n";
	print HRP "OMC_ID;BSC_ID;SITENAME;TRE\n";
	
	my ($tcuno,$abisNo,$freeFr) = (0,0,0);
	my %psCount = ();
	my %seenBTS = ();			#keep track of seen BTS's - used to update Abis count in case of BTS's that are chained together
	foreach my $omc (sort keys %bscConfig) {
		foreach my $bsc (sort keys %{$bscConfig{$omc}}) {
	  		my %seen = ();				#keep track of seen TCU's
	  		my %seenAbis = ();
	  		my %seenCell = ();
	  		my %seenTCU_FR = ();
	  		
	  		my ($bscName,$hw) = @{$bscConfig{$omc}{$bsc}}{qw/NAME CONFIG/};
	  		
	  		my $psCount = 0;
	  		if (exists $g2Tcu{$hw}) {
	  			($tcuno,$abisNo,$freeFr) = ($g2Tcu{$hw},$g2Abis{$hw},$g2Tcu{$hw}*4);
		  		for my $i (1..$tcuno) {
		  			my $tsu;
		  	    my ($rslcount,$omlcount,$sdcount,$tcuload,$frRslCount,$drRslCount) = (0,0,0,0,0,0);
		  	    my $poolUsable = 'YES';
		  			my %rslrate = (rate1 => '',	rate2 => '',rate3 => '',rate4 => ''); 
		  			my %rslnames = (rsl1 => '',	rsl2 => '',	rsl3 => '',	rsl4 => '');
		  			my %omlnames = (oml1 => '',	oml2 => '');
		  				
						foreach my $omcidx (sort keys %completeLapd) {
							next if ($omcidx ne $omc);
							$tsu = int(($i-1)/8) + 1;
									
							foreach my $id (sort keys %{$completeLapd{$omcidx}}) {
								my ($tcu,$BSCID) = @{$completeLapd{$omcidx}{$id}}{qw/TCU BSC_ID/};
								
								next if $bscConfig{$omc}{$BSCID}{'GEN'} ne 'g2';
								next if ($tcu != $i);
								next if ($BSCID != $bsc);
								my ($usage,$rate,$sd,$dyn,$lapdLabel,$equip,$opState) = @{$completeLapd{$omcidx}{$id}}{qw/LapdLinkUsage SpeechCodingRate NBR_SDCCH DYNAMIC UserLabel RelatedGSMEquipment OperationalState/};
											
								my ($sector,$site) = map(compress_name($_),@{$completeLapd{$omcidx}{$id}}{qw/SECTORNAME SITENAME/});
											
								my $trx = "";
								if ($usage eq "rsl") {
									my $relatedSector = $completeLapd{$omcidx}{$id}{"RelatedBtsSector"};
									my ($bts) = ($relatedSector =~ /.*?moiRdn\s(\d+)/);
									my ($sect) = ($relatedSector =~ /amecID.*?moiRdn.*?moiRdn\s(\d+)/);
									#print "$sector, Usage : $usage, sector : $sect\n";
												
									$siteToTSU{$omc}{$bsc}{$bts}{'Prim'} = $tsu;	#primary abis TSU connection
									$siteToTSU{$omc}{$bsc}{$bts}{'Sec'} = '-';		#secondary abis TSU connection
									my $abisTopology = $sector{$omc}{$bsc}{$bts}{'AbisTopology'};
									
									#info for rsl summary csv
									my $abisTwo = $sector{$omc}{$bsc}{$bts}{"2ndAbis"};
									if ($abisTwo =~ /related/) {
										my ($abis2Tsu) = ($abisTopology =~ /chain\:\d+.*?chain\:(\d+)/);
										$abis2Tsu = (int(($abis2Tsu -1)/6) + 1);
										$siteToTSU{$omc}{$bsc}{$bts}{'Sec'} = $abis2Tsu;
									}
									
									if (not exists($seenAbis{$abisTopology})) {
										if ($abisTopology =~ /chain/) {
											$abisNo--;
											$abisNo-- if ($abisTwo =~ /related/);
										}
										elsif ($abisTopology =~ /ring/) {
											$abisNo -= 2;
										}
									}
		
									$abisCap{$omc}{$bsc}{$bts} += 2;							#count TS taken up by TRE
									
									
									if (not exists($seen{$abisTopology}{$tcu})) {
											$abisCap{$omc}{$bsc}{$bts}++ ;
									}		#count RSL's - RSL's (and OML) from TRE's (BTS) on same TCU are muxed together (my discovery)
									
									my $ci = $sector{$omc}{$bsc}{$bts}{$sect}{"CI"};
									
									$seen{$abisTopology}{$tcu}++;
									$seenAbis{$abisTopology}++;
									$seenBTS{$omc}{$bsc}{$abisTopology}{$bts}++;
									$seenCell{$abisTopology}{$bts}{$sect}++;
									$rslcount++;
									$sdcount+=$sd;
									($trx) = ($lapdLabel =~ /RSL\s(\d+)/);
									my $hrFlag = $sector{$omc}{$bsc}{$bts}{$sect}{"HR_ENABLED"};
									#print "$sector, TRX $trx Flag : $hrFlag, $rate\n";
									if ($rate eq 'fullRate') {
										$frCap{$omc}{$bsc}{$tsu}{'RSL_ON_TSU'}++;
										$freeCap{$omc}{$bsc}{$tsu}{'RSL_ON_TSU'}++;
										$tcuload += 0.25;
										$frRslCount++;
										$freeFr--;
									}
									elsif ($rate eq 'multiRate') {
										$poolUsable = 'NO';
										if ($hrFlag ne 'TRUE') {
											#print "RSL's are DR but HalfRate not enabled on $sector\n" if ($hrFlag ne 'TRUE');
											print HRP "$omc;$bsc;".$completeLapd{$omcidx}{$id}{"SECTORNAME"}.";$trx\n";
											$rate = 'problemRate';		#:-)
										}
										$frCap{$omc}{$bsc}{$tsu}{'RSL_ON_TSU'}+= 4 if not exists($seenTCU_FR{$tcu});
										$freeFr -= 4 if not exists($seenTCU_FR{$tcu});
										$seenTCU_FR{$tcu} = 1;
										$freeCap{$omc}{$bsc}{$tsu}{'RSL_ON_TSU'} += 2;
										$tcuload += 0.5;
										$drRslCount++;
									}
									$rslrate{'rate'.$rslcount} = $rate;
									$rslnames{'rsl'.$rslcount} = $sector."($trx)($sd)($dyn)";
								}	#end of usage eq 'rsl'
								elsif ($usage eq "om") {
									my ($bts) = ($equip =~ /equipmentHolderID.*?equipmentHolderID.*?moiRdn\s(\d+)/);
									next if ($opState eq 'disabled');
									$bts -= 2;
									my $abisTopology = $sector{$omc}{$bsc}{$bts}{'AbisTopology'};
									
									if (not exists($seen{$abisTopology}{$tcu})) {
										$abisCap{$omc}{$bsc}{$bts}++;
										#print "Adding +1 for OML\n" if ($bts == 12);
									}	#count OML's
									$omlcount++;
									$omlnames{'oml'.$omlcount} = $site;
								}
							}
					}
			$poolUsable = 'NO' if ($tcuload == 1);
			print RSLCONF "$omc;$bsc;$bscName;$tsu;$i;$rslcount;$frRslCount;$drRslCount;$omlcount;$rslnames{'rsl1'};$rslrate{'rate1'};$rslnames{'rsl2'};$rslrate{'rate2'};$rslnames{'rsl3'};$rslrate{'rate3'};$rslnames{'rsl4'};$rslrate{'rate4'};$omlnames{'oml1'};$omlnames{'oml2'};$sdcount;$tcuload;$poolUsable\n";
		}
	}# end of: if (defined $g2Tcu{$hw})
		
		
		}	#end foreach my $bsc
	 }
	 #update Abis counts with Extra PS timeslot info
	 #$sector{$omc}{$bsc}{$bts}{$sect}
	 foreach my $omc (keys %sector) {
	 	foreach my $bsc (keys %{$sector{$omc}}) {
	 		my %tsPrCount = ();		#count number of extra TS assigned to primary abis in case of two abis scenario and MAX_EXTRA_TS_PRIMARY parameter setting
	 		foreach my $bts (keys %{$sector{$omc}{$bsc}}) {
	 			my $abisTopology = $sector{$omc}{$bsc}{$bts}{'AbisTopology'};
				$tsPrCount{$abisTopology}{$bts} = 0 if not exists($tsPrCount{$abisTopology}{$bts});
				my $abisTwo = $sector{$omc}{$bsc}{$bts}{"2ndAbis"};
				my $totalExtraTs = ($sector{$omc}{$bsc}{$bts}{"TotalExtraTs"} || 0);
				#print "$omc $bsc $bts $totalExtraTs TsPrim ",$sector{$omc}{$bsc}{$bts}{'MaxExtraTsPrimary'}," AbisCap ",$abisCap{$omc}{$bsc}{$bts},"\n";		
				my $breakLoop = 32;
				while (($totalExtraTs > 0) && ($breakLoop > 0)) {
					if (($tsPrCount{$abisTopology}{$bts} < $sector{$omc}{$bsc}{$bts}{'MaxExtraTsPrimary'}) && ($abisCap{$omc}{$bsc}{$bts} < 31)) {	#assign first to primary Abis
						my $priTsu = $siteToTSU{$omc}{$bsc}{$bts}{'Prim'};
						$totalExtraTs -= 2;
						$abisCap{$omc}{$bsc}{$bts} += 2;
						$tsPrCount{$abisTopology}{$bts} += 2;
						$psCount{$omc}{$bsc}{$priTsu} += 2;
						$frCap{$omc}{$bsc}{$priTsu}{'RSL_ON_TSU'}++;
						$freeCap{$omc}{$bsc}{$priTsu}{'RSL_ON_TSU'}++;
					}
					else {
						if ($abisTwo =~ /related/) {
							my $secTsu = $siteToTSU{$omc}{$bsc}{$bts}{'Sec'};
							$totalExtraTs -= 2;
							$abis2Cap{$omc}{$bsc}{$bts} += 2;
							$psCount{$omc}{$bsc}{$secTsu} += 2;
							$frCap{$omc}{$bsc}{$secTsu}{'RSL_ON_TSU'}++;
							$freeCap{$omc}{$bsc}{$secTsu}{'RSL_ON_TSU'}++;
						}
					}
					$breakLoop--;
				}
	 		}
	 	}
	}
	#update Abis count's for BTS's that are chained together
	foreach my $omc (keys %seenBTS) {
		foreach my $bsc (keys %{$seenBTS{$omc}}) {
			foreach my $aT (keys %{$seenBTS{$omc}{$bsc}}) {
				my $totCount = 0;
				my @bts = keys (%{$seenBTS{$omc}{$bsc}{$aT}});
				if ($#bts>0) {
					foreach my $chBts (@bts) {
						$totCount += $abisCap{$omc}{$bsc}{$chBts};
					}
					foreach my $chBts (@bts) {
						$abisCap{$omc}{$bsc}{$chBts} = $totCount;
					}
				}
			}
		}
	}
	 
	#save extra PS info
	open(PSCONF,">".$config{"OUTPUT_CSV"}."psConfig.csv") || die "Cannot open psConfig.csv: $!\n";
	print PSCONF "OMC_ID;BSC_ID;TSU;TOTAL_PS_AMOUNT\n";
	foreach my $omc (keys %psCount) {
		foreach my $bsc (keys %{$psCount{$omc}}) {
			foreach my $tsu (keys %{$psCount{$omc}{$bsc}}) {
				print PSCONF "$omc;$bsc;$tsu;".$psCount{$omc}{$bsc}{$tsu}."\n";
			}
		}
	}
	 close(PSCONF) || die "Cannot close psConfig.csv: $!\n";
	 close(RSLCONF) || die "Cannot close rslConfig.csv: $!\n";
	 close(HRP) || die "Cannot close hrProblem.csv: $!\n";	
	 print "END:Compiling RSL Configuration\n";
}

sub getRadioInfo {
	my ($bsc,$bts);
	foreach my $omc (keys %circuit) {
		foreach my $id (keys %{$circuit{$omc}}) {
			my ($moiRdn,$rack,$shelf,$slot) = ($id =~ /.*?amecID\s\d+.*?moiRdn\s(\d+).*?rackRdn\s(\d+).*?shelfRdn\s(\d+).*?moiRdn\s(\d+).*?/);
			next if ($moiRdn == 1);						#BSC - exclude from this count
			my $suppObj = $circuit{$omc}{$id}{"SupportedByObjectList"};
			next if ($suppObj eq '{}');
			my $sector = $circuit{$omc}{$id}{"BtsSector"};
			my $type = $circuit{$omc}{$id}{"CircuitPackType"};
			($bsc,$bts) = ($suppObj =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
			
			$sector{$omc}{$bsc}{$bts}{"uBTS"} = "-" if not defined($sector{$omc}{$bsc}{$bts}{"uBTS"});
			if (($rack == 1) && ($shelf == 1) && ($slot == 0)) {
				if ($type =~ /(\d+)/) {
					$sector{$omc}{$bsc}{$bts}{"uBTS"} = 'M'.$1.'M';
				}
			}
			#get frontend Amp info
			if ($type =~ /\"tma/) {
				$sector{$omc}{$bsc}{$bts}{"FE_AMP"} = $type;
			}
			#get radio control info
			if (($type =~ /\"sum/) or ($type =~ /\"scfe/) or ($type =~ /\"omu/)) {
				$sector{$omc}{$bsc}{$bts}{"CONTROL"} = $type;
			}
			#get possible frame unit info
			if (($type =~ /\"fumo/) or ($type =~ /\"fuco/) or ($type =~ /\"drfu/)) {
				$sector{$omc}{$bsc}{$bts}{$type}++;
			}
			next if ($sector eq 'stationUnitSharing');		#no idea yet what this sector type means <- need to find out ASAP
			#next if ($sector eq 'undefined');
			if ($sector eq 'undefined') {
				$sector = 'sector4';
			}
			
			
			#get radio info
			next if not(($type =~ /^\"t[r|x|a|g]/) or ($type =~ /^\"anx/) or ($type =~ /^\"any/) or ($type =~ /^\"anc/));
			($sector) = ($sector =~ /sector(\d+)/);
			for (qw/ANX_COUNT ANY_COUNT ANC_COUNT TRA_AMOUNT TRE_AMOUNT/) {
				$sector{$omc}{$bsc}{$bts}{$sector}{$_} = 0 if not defined($sector{$omc}{$bsc}{$bts}{$sector}{$_});
			}
			for (qw/ANX ANY ANC/) {
				$sector{$omc}{$bsc}{$bts}{$sector}{$_} = '' if not defined($sector{$omc}{$bsc}{$bts}{$sector}{$_});	
				if ($type =~ /$_/i) {
					$sector{$omc}{$bsc}{$bts}{$sector}{$_} = $type;
					$sector{$omc}{$bsc}{$bts}{$sector}{$_."_COUNT"}++;
				}
			}
			$sector{$omc}{$bsc}{$bts}{$sector}{"TRA_EQUIPPED"} = 'FALSE' if not exists($sector{$omc}{$bsc}{$bts}{$sector}{"TRA_EQUIPPED"});
			next if not($type =~ /^\"t[r|x|a|g]/);
			
			$type =~ s/\"//g;
			$sector{$omc}{$bsc}{$bts}{$sector}{$type}++;
			$radioTypes{$type} = 1;
			if ($type =~ /a/) {																	
				$sector{$omc}{$bsc}{$bts}{$sector}{"TRA_EQUIPPED"} = 'TRUE';
				$sector{$omc}{$bsc}{$bts}{$sector}{"TRA_AMOUNT"}++;
			}
			elsif ($type =~ /tgt/) {
				$sector{$omc}{$bsc}{$bts}{$sector}{"TRA_EQUIPPED"} = 'TRUE';
				$sector{$omc}{$bsc}{$bts}{$sector}{"TRA_AMOUNT"}++;
			}
			else {
				$sector{$omc}{$bsc}{$bts}{$sector}{"TRE_AMOUNT"}++;
			}
		}
	}
	print "END:Adding Radio Info\n";
}


sub getAbisInfo {
	my %abis = (
  		"AlcatelAbisChainRingInstanceIdentifier"	=>1,
  		"QmuxTSInfo"					=>1,
  		"AbisTopology"					=>1,
  		"TtpNumber"					=>1,
  		"AbisTtpNumberForARing"				=>1,
  		"UserLabel"					=>1,
  		"BtsList"					=>1
  		);
  	my %element = (
  		"AlcatelManagedElementInstanceIdentifier"	=>1,
  		"RelatedAbisChainRing"				=>1,
  		"SupportedByObjectList"				=>1,
  		"OperationalState"				=>1,
  		"EquipmentType"					=>1,
  		"UserLabel"					=>1
  		);
  	my %abisReport = ();
	
  	print "Compiling Abis Info\n";
  	loadACIE("AlcatelAbisChainRing","eml",\%abis);
  	foreach my $omc (keys %abis) {
  		foreach my $id (keys %{$abis{$omc}}) {
  			my ($topology,$ttpRing,$ttp,$label) = @{$abis{$omc}{$id}}{qw/AbisTopology AbisTtpNumberForARing TtpNumber UserLabel/};
  			if ($topology eq 'ring') {
  				($ttpRing) = ($ttpRing =~ /number:(\w+)/);
  				$abis{$omc}{$id}{"AbisTopology"} = $topology.":".$ttp."/".$ttpRing;
  			}
  			else {
  				$abis{$omc}{$id}{"AbisTopology"} = $topology.":".$ttp;
  			}
  			if ($label =~ /.*?\d+\W+(\w+)/) {
  				$abis{$omc}{$id}{"DXX_FLAG"} = $1;
  			}
  			else {
  				$abis{$omc}{$id}{"DXX_FLAG"} = '';
  			}
  		}
	}
	
	loadACIE("AlcatelManagedElement","eml",\%element);
	my ($bsc,$bts);
	foreach my $omc (keys %element) {
  	foreach my $id (keys %{$element{$omc}}) {
  		my $type = $element{$omc}{$id}{"EquipmentType"};
  		next if not($type =~ /bts/);
  		my $btsId = $element{$omc}{$id}{"SupportedByObjectList"};
  		($bsc,$bts) = ($btsId =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
  			
  		my $relatedAbis = $element{$omc}{$id}{"RelatedAbisChainRing"};
  		($relatedAbis) = ($relatedAbis =~ /relatedObject\:(.*)/);
  		my $rank = get_rank($abis{$omc}{$relatedAbis}{'BtsList'},$id);
  		$sector{$omc}{$bsc}{$bts}{"AbisTopology"} = $abis{$omc}{$relatedAbis}{"AbisTopology"};
  		my $abis2 = $sector{$omc}{$bsc}{$bts}{"2ndAbis"};
  		if ($abis2 =~ /relatedObject/) {
  			$abis2 =~ s/relatedObject\://;
  			my $chain2 = $abis{$omc}{$abis2}{"AbisTopology"};
  			$sector{$omc}{$bsc}{$bts}{"AbisTopology"} .= "/".$chain2;
  		}
  		my $qmuxts = 'noQmux';
  		$qmuxts = $1 if ($abis{$omc}{$relatedAbis}{"QmuxTSInfo"} =~ /timeslotNumber\:(.*)/);
		@{$sector{$omc}{$bsc}{$bts}}{qw/QmuxTS RANK DXX_FLAG/} = ($qmuxts,$rank,$abis{$omc}{$relatedAbis}{"DXX_FLAG"});
  	}
  }
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


sub compress_name {
	my ($cellname, $dummy) = @_;
	return("") if not defined($cellname);
	my ($last);
	# remove unconditionally all quotes
	return (&compress_name($cellname)) if ($cellname =~ s/\"//g);
	# remove unconditionally all underscores (for consistency)
	return (&compress_name($cellname)) if ($cellname =~ s/_//g);
	# exit condition
	return ($cellname) if (length($cellname) <= CELL_NAME_SIZE);
	# we didn't find underscores - remove vowels (only lowercase!) starting from right
	return(&compress_name($1.$2)) if ($cellname =~ /(.*)[aioue](.*)$/);
	# last resort - chop from the right end, except rightmost...
	#uncommented - this part is chopping out some SD Count's
	$last = chop($cellname);
	chop ($cellname);
	return (&compress_name($cellname.$last));
}


__END__


