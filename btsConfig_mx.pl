#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# Compile BTS configuration info
use strict;
#use warnings;
use Data::Dumper;

#constants
use constant CELL_NAME_SIZE => 18;


require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
require "loadACIEsubs.pl";

unless (-e $href->{"OUTPUT_CSV"}."sdcchConfig.csv") {
	
}


#variables
my %radioTypes = ();
my %sector = ();
my %abis_ts_info = ();
my %bts_rsl_load = ();

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
my @btsColms = qw/SITE_NAME BTS_GENERATION uBTS QMuxAddress PowerLevel MuxRule AdministrativeState OperationalState AbisTopology 2ndAbis SynchBts QmuxTS RANK DXX_FLAG FE_AMP CONTROL Abis_TS_Free TotalExtraTs/;
my @celColms = qw/CELL_NAME LAC CI SECTOR TRX_NUM TRA_EQUIPPED TRA_AMOUNT TRE_AMOUNT BCCHFrequency SECTOR_RSL_NUM Availability MaxEgprsMcs AGprsMinPdch AGprsMaxPdchHighLoad AGprsMaxPdch Radio_Type/;

my %btsData = ();
my %celData = ();
my @radios = sort keys %radioTypes;



open my $bts_file,">",$href->{'OUTPUT_CSV'}.'btsConfig.csv' || die "Cannot open btsConfig.csv: $!\n";
print $bts_file "OMC;BSC_ID;BSC_NAME;".join(';',@bscCols).";BTS_ID;".join(';',@btsColms).";".join(';',@celColms).";".join(';',@radios)."\n";
my $count = 0;
foreach my $omc (keys %sector) {
	foreach my $bsc (keys %{$sector{$omc}}) {
		my $bscName = $rnlBSC{$omc}{$bsc}{"UserLabel"} || "NO_RNL_BSC_".$bsc;
		foreach my $bts (keys %{$sector{$omc}{$bsc}}) {
			my $bts_id = join(';',$omc,$bsc,$bts);
			
			for (@btsColms) {
				$btsData{$_} = '-';
				$btsData{$_} = $sector{$omc}{$bsc}{$bts}{$_} if (exists($sector{$omc}{$bsc}{$bts}{$_}));
			}
			$btsData{'QMuxAddress'} =~ s/number\:(\d+)/$1/;
			my $abis_topo = $sector{$omc}{$bsc}{$bts}{"AbisTopology"};
			$abis_ts_info{$omc}{$bsc}{$abis_topo} += $sector{$omc}{$bsc}{$bts}{'TotalExtraTs'};
			$abis_ts_info{$omc}{$bsc}{$abis_topo}++ if ($btsData{'QmuxTS'} ne 'noQmux');
			my ($fr_tre,$dr_tre) = 	@{$bts_rsl_load{$bts_id}}{qw/FR_RSL DR_RSL/};
			 
			$btsData{'Abis_TS_Free'} = '?';
			
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
				print $bts_file "$omc;$bsc;$bscName;".join(';',@{$bscConfig{$omc}{$bsc}}{@bscCols}).";$bts;".join(';',@btsData{@btsColms}).";".join(';',@celData{@celColms}).";".join(';',@radioTypes{@radios})."\n";	
			}
		}
	}
}
close $bts_file;
print "--END:Compiling BTS Config Information:END--\n";


## subroutines from here
sub getSectorInfo {
	my %bbtNum = ();
	my %btsSector = ();
	my %rnlBsc = ();
	my %btsSite = ();
	my %cell = ();
	
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
	open my $edge_file,">",$href->{'OUTPUT_CSV'}."dataConfig.csv" || die "Cannot open dataConfig.csv: $!\n";
	print $edge_file "OMC;BSC;BTS;LAC;CI;CELLNAME;GPRS;EDGE;EXTRAABISTS;MAXGPRSCS;MAXEGPRSMCS\n";
	loadACIE("RnlAlcatelBSC","rnl",\%rnlBsc);
	loadACIE("AlcatelBts_Sector","eml",\%btsSector);
	
	foreach my $omc (keys %btsSector) {
		foreach my $id (keys %{$btsSector{$omc}}) {
			($bsc,$bts,$sector) = ($id =~ /amecID\s(\d+).*?moiRdn\s(\d+).*?moiRdn\s(\d+)/);
			my $globalId = $btsSector{$omc}{$id}{"CellGlobalIdentity"};			
			($lac,$ci) = ($globalId =~ /lac\s(\d+).*?ci\s(\d+)/);
			
			@{$sector{$omc}{$bsc}{$bts}{$sector}}{qw/LAC CI BCCHFrequency HR_ENABLED CELL_NAME Availability/} = ($lac,$ci,$btsSector{$omc}{$id}{"BCCHFrequency"},$btsSector{$omc}{$id}{"HR_ENABLED"},$btsSector{$omc}{$id}{"UserLabel"},$a{$btsSector{$omc}{$id}{"AvailabilityStatus"}});
			@{$sector{$omc}{$bsc}{$bts}{$sector}}{qw/SECTOR_RSL_NUM EnGprs EnEgprs/} = ($btsSector{$omc}{$id}{"NbBaseBandTransceiver"},$btsSector{$omc}{$id}{"EnGprs"},$btsSector{$omc}{$id}{"EnEgprs"});
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
			print $edge_file "$omc;$bsc;$bts;$lac;$ci;".$btsSector{$omc}{$id}{"UserLabel"}.";$gprsOn".";$edgeOn;".$sector{$omc}{$bsc}{$bts}{$sector}{"ExtaAbisTs"}.";".$sector{$omc}{$bsc}{$bts}{$sector}{"MaxGprsCs"}.";".$sector{$omc}{$bsc}{$bts}{$sector}{"MaxEgprsMcs"}."\n";
		}
	}
	close $edge_file;
	print "END:Compiling BtsSector Info\n";
}



#NOTE : sdcchConfig.csv has to exist ! Therefore, sdcchConfig.pl has to be run prior to btsConfig.pl

sub getLapdLinkInfo {
	#load SDCCH info
	print "Retrieving SDCCH info\n";
	open my $sdcch_file,"<",$href->{'OUTPUT_CSV'}."sdcchConfig.csv" || die "Cannot open sdcchConfig.csv: $!\n";
	my @cols;
	my %line = ();
	my %sdcch = (); 
	while (<$sdcch_file>) {
		chomp;
		if ($. == 1) {				#load header line
			@cols = split(/;/,$_);
		}
		else {
			my @data = split(/;/,$_);
			@line{@cols} = @data;
			@{$sdcch{$line{"OMC_ID"}}{$line{"BSC"}}{$line{"BTS"}}{$line{"SECTOR"}}{$line{"TRX"}}}{qw/NBR_SDCCH DYNAMIC/} = @line{qw/NBR_SDCCH DYNAMIC/};
		}
	}
	close $sdcch_file;
	print "END: Retrieving SDCCH info\n";
	print "Retrieving BSC info\n";
  	open my $bsc_file,"<",$href->{'OUTPUT_CSV'}."bscConfig.csv" || die "Cannot open bscConfig.csv: $!\n";
	while (<$bsc_file>) {
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
	close $bsc_file;
	print "END: Retrieving BSC info\n";
	
	#retrieve basic LapD info
	my %lapd = ();
	my %btsSector = ();
	my %bSite = ();
	my %completeLapd = ();
	my %ccpLoad = ();
	my %ccpBtsLoad = ();
	my %siteControl = ();
	loadACIE("AlcatelLapdLink","eml",\%lapd);
	loadACIE("AlcatelBts_Sector","eml",\%btsSector);
	loadACIE("AlcatelBtsSiteManager","eml",\%bSite);
	#first load all CCP info - in case some have no RSLs assigned, they will still show up
	foreach my $omc (keys %circuit) {
		foreach my $id (keys %{$circuit{$omc}}) {
			next unless $circuit{$omc}{$id}{'CircuitPackType'} =~ /ccp/i;
			next if $circuit{$omc}{$id}{'ActiveStandbyMode'} eq 'standby';
			my ($moiRdn,$rack,$shelf,$slot) = ($id =~ /.*?amecID\s\d+.*?moiRdn\s(\d+).*?rackRdn\s(\d+).*?shelfRdn\s(\d+).*?moiRdn\s(\d+).*?/);
			my ($bscid,$bts) = ($circuit{$omc}{$id}{'SupportedByObjectList'} =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
			my $bsc_name = $bscConfig{$omc}{$bscid}{'NAME'};
			my $ccpId = join(';',$omc,$bscid,$bsc_name,$rack,$shelf,$slot);
			@{$ccpLoad{$ccpId}}{qw/ActiveStandbyMode FR_RSL DR_RSL EQ_FR FREE_RSL/} = ($circuit{$omc}{$id}{'ActiveStandbyMode'},0,0,0,200);
		}
	}
	
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
				
			}
			else {
				($rack,$shelf,$slot) = ($equip =~ /rackRdn\s(\d+).*?shelfRdn\s(\d+).*?moiRdn\s(\d+)/);
				$siteControl{join(';',$omc,$bscid,$bts)}{join(',',$rack,$shelf,$slot)}++;
				
				
				my ($circuitId) = ($lapd{$omc}{$id}{'RelatedGSMEquipment'} =~ /^\{(.*)\}$/);
				my $bName = $bscConfig{$omc}{$bscid}{'NAME'};
				my $ccpId = join(';',$omc,$bscid,$bName,$rack,$shelf,$slot);
				my $btsId = join(';',$omc,$bscid,$bts);
				my $siteId = '{ amecID '.$bscid.', moiRdn '.$bts.'}';
				my $btsName = $bSite{$omc}{$siteId}{'UserLabel'};
				
				if ($lapd{$omc}{$id}{'LapdLinkUsage'} eq 'rsl') {
					my $abis_topo = $sector{$omc}{$bscid}{$bts}{"AbisTopology"};
					$abis_ts_info{$omc}{$bscid}{$abis_topo} += 2;
					my $bName = $bscConfig{$omc}{$bscid}{'NAME'};
					$ccpLoad{$ccpId}{'ActiveStandbyMode'} = $circuit{$omc}{$circuitId}{'ActiveStandbyMode'};
					$ccpBtsLoad{$ccpId}{$btsName}{'FR_RSL'} = 0 if not exists $ccpBtsLoad{$ccpId}{$btsName}{'FR_RSL'};
					$ccpBtsLoad{$ccpId}{$btsName}{'DR_RSL'} = 0 if not exists $ccpBtsLoad{$ccpId}{$btsName}{'DR_RSL'};
					$bts_rsl_load{$btsId}{'FR_RSL'} = 0 if not exists $bts_rsl_load{$btsId}{'FR_RSL'};
					$bts_rsl_load{$btsId}{'DR_RSL'} = 0 if not exists $bts_rsl_load{$btsId}{'DR_RSL'};
					if ($lapd{$omc}{$id}{'SpeechCodingRate'} eq 'fullRate') {
						$ccpLoad{$ccpId}{'FR_RSL'}++;
						$bts_rsl_load{$btsId}{'FR_RSL'}++;
						$ccpBtsLoad{$ccpId}{$btsName}{'FR_RSL'}++;
					}
					if ($lapd{$omc}{$id}{'SpeechCodingRate'} eq 'multiRate') {
						$ccpLoad{$ccpId}{'DR_RSL'}++;
						$bts_rsl_load{$btsId}{'DR_RSL'}++;
						$ccpBtsLoad{$ccpId}{$btsName}{'DR_RSL'}++;
					}
					$ccpBtsLoad{$ccpId}{$btsName}{'BSC_NAME'} = $bName;
					
					
					if ((defined $rnlBSC{$omc}{$bscid}{'En4DrTrePerTcu'}) && ($rnlBSC{$omc}{$bscid}{'En4DrTrePerTcu'} eq 'TRUE')) {
						$ccpLoad{$ccpId}{'EQ_FR'} = ($ccpLoad{$ccpId}{'FR_RSL'}||0) + ($ccpLoad{$ccpId}{'DR_RSL'}||0);
					}
					else {
						$ccpLoad{$ccpId}{'EQ_FR'} = ($ccpLoad{$ccpId}{'FR_RSL'}||0) + 2*($ccpLoad{$ccpId}{'DR_RSL'}||0);
					}
					
					$ccpLoad{$ccpId}{'FREE_RSL'} = 200 - $ccpLoad{$ccpId}{'EQ_FR'};
				}
				elsif ($lapd{$omc}{$id}{'LapdLinkUsage'} eq 'om') {
				}
			}
			@{$completeLapd{$omc}{$id}}{qw/RACK SHELF SLOT/} = ($rack,$shelf,$slot);
			
			
			if (exists($sdcch{$omc}{$bscid}{$bts}{$sector}{$trx}{"NBR_SDCCH"})) {
				@{$completeLapd{$omc}{$id}}{qw/NBR_SDCCH DYNAMIC/} = @{$sdcch{$omc}{$bscid}{$bts}{$sector}{$trx}}{qw/NBR_SDCCH DYNAMIC/}
			}
			else {
				($completeLapd{$omc}{$id}{"NBR_SDCCH"},$completeLapd{$omc}{$id}{"DYNAMIC"}) = (0,0);
			}
			
			for (qw/LapdLinkUsage SpeechCodingRate RelatedBtsSector RelatedGSMEquipment OperationalState UserLabel/) {
				$completeLapd{$omc}{$id}{$_} = $lapd{$omc}{$id}{$_};
			}
			$completeLapd{$omc}{$id}{"SITENAME"} = '';							#initialize
		}
	}
	#exit; - debugging
	#insert siteName Info into Lapd
	my %btsSite = ();
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
  my @lapdCols = qw/LapdLinkUsage SpeechCodingRate UserLabel BSC_ID RACK SHELF SLOT SECTORNAME SITENAME LAC CI ABIS_TOPOLOGY NBR_SDCCH DYNAMIC/;
  open(LAPD,">".$href->{'OUTPUT_CSV'}."lapdConfig.csv") || die "Cannot open lapdConfig.csv: $!\n";
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
  open(CCP,">".$href->{'OUTPUT_CSV'}."ccpLoad.csv") || die "Cannot open ccpLoad.csv: $!\n";
  print CCP "OMC_ID;BSC_ID;BSC_NAME;RACK;SHELF;SLOT;En4DrTrePerTcu;".join(';',@ccpCols)."\n";
  foreach my $id (keys %ccpLoad) {
  	my ($omc,$bsc,undef) = split(';',$id);
  	print CCP join(';',$id,$rnlBSC{$omc}{$bsc}{'En4DrTrePerTcu'},@{$ccpLoad{$id}}{@ccpCols})."\n";
  }
  close(CCP);
  
  my @cbtsCol = qw(BSC_NAME FR_RSL DR_RSL);
  open(CCPBTS,">".$href->{'OUTPUT_CSV'}."ccpBtsLoad.csv") || die "Cannot open ccpBtsLoad.csv: $!\n";
  print CCPBTS "OMC_ID;BSC_ID;RACK;SHELF;SLOT;BTSNAME;".join(';',@cbtsCol)."\n";
  foreach my $id (keys %ccpBtsLoad) {
  	foreach my $bts (keys  %{$ccpBtsLoad{$id}}) {
  		print CCPBTS join(';',$id,$bts,@{$ccpBtsLoad{$id}{$bts}}{@cbtsCol})."\n";
  	}
  }
  close(CCPBTS);
  
  open(SITEC,">".$href->{'OUTPUT_CSV'}."siteControl.csv") || die "Cannot open siteControl.csv: $!\n";
  print SITEC "OMC_ID;BSC_ID;BTS_ID;CONTROL\n";
  foreach my $id (keys %siteControl) {
  	my $cntl = join(' / ',sort keys %{$siteControl{$id}});
  	print SITEC join(';',$id,$cntl)."\n";
  }
  close(SITEC);
  
	print "END:Compiling RSL Configuration\n";
}

sub getRadioInfo {
	foreach my $omc (keys %circuit) {
		foreach my $id (keys %{$circuit{$omc}}) {
			my ($moiRdn,$rack,$shelf,$slot) = ($id =~ /.*?amecID\s\d+.*?moiRdn\s(\d+).*?rackRdn\s(\d+).*?shelfRdn\s(\d+).*?moiRdn\s(\d+).*?/);
			next if $moiRdn == 1;						#BSC - exclude from this count
			my ($suppObj,$sector,$type) = @{$circuit{$omc}{$id}}{qw/SupportedByObjectList BtsSector CircuitPackType/};
			next if $suppObj eq '{}';
			$type =~ s/\"//g;
			my ($bsc,$bts) = ($suppObj =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
			
			if (($rack == 1) && ($shelf == 1) && ($slot == 0)) {
				$sector{$omc}{$bsc}{$bts}{"uBTS"} = 'M'.$1.'M' if ($type =~ /(\d+)/);
				next;
			}
			
			#get radio control info
			$sector{$omc}{$bsc}{$bts}{"CONTROL"} = $type if $type =~ /sum/i;
			
			next if $sector eq 'stationUnitSharing';		#no idea yet what this sector type means <- need to find out ASAP
			#next if ($sector eq 'undefined');
			$sector = 'sector4' if $sector eq 'undefined';
			
			
			#get radio info
			next if not(($type =~ /^t[r|x|a|g]/) || ($type =~ /^a[n|g]/i) );
			$radioTypes{$type} = 1;
			my ($s_num) = ($sector =~ /sector(\d+)/);
			$sector{$omc}{$bsc}{$bts}{$s_num}{$type}++;
			
			
			next unless ($type =~ /^t[r|x|a|g]/);
			
			if ( ($type =~ /a/i) || ($type =~ /tgt/i) ) {																	
				$sector{$omc}{$bsc}{$bts}{$s_num}{"TRA_EQUIPPED"} = 'TRUE';
				$sector{$omc}{$bsc}{$bts}{$s_num}{"TRA_AMOUNT"}++;
				$sector{$omc}{$bsc}{$bts}{$s_num}{"TRE_AMOUNT"} = 0 unless exists($sector{$omc}{$bsc}{$bts}{$s_num}{"TRE_AMOUNT"});
			}
			else {
				$sector{$omc}{$bsc}{$bts}{$s_num}{"TRA_EQUIPPED"} = 'FALSE' unless exists($sector{$omc}{$bsc}{$bts}{$s_num}{"TRA_EQUIPPED"});
				$sector{$omc}{$bsc}{$bts}{$s_num}{"TRE_AMOUNT"}++;
				$sector{$omc}{$bsc}{$bts}{$s_num}{"TRA_AMOUNT"} = 0 unless exists($sector{$omc}{$bsc}{$bts}{$s_num}{"TRA_AMOUNT"});
			}
		}
	}
	print "END:Adding Radio Info\n";
}


sub getAbisInfo {
	my %abis = ();
  	my %element = ();
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
	foreach my $omc (keys %element) {
  	foreach my $id (keys %{$element{$omc}}) {
  		my $type = $element{$omc}{$id}{"EquipmentType"};
  		next unless ($type =~ /bts/);
  		my $btsId = $element{$omc}{$id}{"SupportedByObjectList"};
  		my ($bsc,$bts) = ($btsId =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
  			
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


