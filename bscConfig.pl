#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# Assembles BSC config data for all BSC's
use strict;
use warnings;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";

my %emlBsc = (
	"AlcatelBscInstanceIdentifier"	=>1,
	"BSC_Generation"		=>1,
	"BSC_HW_Config"			=>1,
	"UserLabel"			=>1,
	"IMPORTDATE"			=>1
	);
my %rnlBsc = (
	"RnlAlcatelBSCInstanceIdentifier" => 1,
	"RnlRelatedMFS" => 1
	);
my %rnlMfs = (
	"RnlAlcatelMFSInstanceIdentifier" => 1,
	"MfsGeneration" => 1,
	"UserLabel" => 1
	);
my %x25 = (
	"AlcatelX25LinkInstanceIdentifier"	=>1,
	"X25LinkType"				=>1,
	"PrimaryNsap"				=>1,
	"SecondaryNsap"				=>1
	);
my %mtp = (
	"MtpSignPointInstanceIdentifier"	=>1,
	"PointCode"				=>1
	);
my %setTp = (
	"AlcatelSignLinkSetTpInstanceIdentifier"=>1,
	"AdjPc"					=>1
	);
my %ttp = (
	"Alcatel2MbTTPInstanceIdentifier"	=>1,
	"AdministrativeState"			=>1,
	"OperationalState"	=>1,
	"TTPtype"				=>1,
	"GslUsage"			=>1,
	"AterMuxGprsUsage"	=>1,
	"UserLabel"			=>1
	);
my %n7 = (
	"AlcatelSignLinkN7InstanceIdentifier"	=>1,
	"AdministrativeState"			=>1,
	"UserLabel"				=>1
	);
my %cell = (
	"CellInstanceIdentifier" => 1,
	"ACmbRaCode" => 1,
	"CellGlobalIdentity" => 1,
	"RnlSupportingSector" => 1
	);
	
my %mlNE = (
	"NetworkElementInstanceIdentifier" => 1,
	"NetworkAddress" => 1
);

my %ipLink = (
	"AlcatelIPLinkInstanceIdentifier" => 1,
	"IpLinkIpAddress" => 1,
	"IpLinkType" => 1
);

print "--Compiling BSC Config Information--\n";
my %bscConfig = ();
loadACIE("RnlAlcatelBSC","rnl",\%rnlBsc);
loadACIE("RnlAlcatelMFS","rnl",\%rnlMfs);
loadACIE("NetworkElement","ml",\%mlNE);
loadACIE("AlcatelIPLink","eml",\%ipLink);

foreach my $omc (keys %rnlBsc) {
	foreach my $id (keys %{$rnlBsc{$omc}}) {
		my $ipID = '{ aIPCoordinatorID { amecID '.$id.', moiRdn 1}, moiRDN 1}';
		my $bscNet = exists($ipLink{$omc}{$ipID}) ?$ipLink{$omc}{$ipID}{'IpLinkIpAddress'} : '-';
		
		my $mfs = $rnlBsc{$omc}{$id}{'RnlRelatedMFS'};
		@{$bscConfig{$omc}{$id}}{qw/MFS_ID MFS_NAME MFS_GEN MFSIPADDRESS BSCIPADDRESS/} = ($mfs,@{$rnlMfs{$omc}{$mfs}}{qw/UserLabel MfsGeneration/},$mlNE{$omc}{$mfs}{'NetworkAddress'},$bscNet);
	}
}
loadACIE("AlcatelBsc","eml",\%emlBsc);
loadACIE("Cell","rnl",\%cell);
foreach my $omc (keys %cell) {
	foreach my $id (keys %{$cell{$omc}}) {
		my ($bscid) = ($cell{$omc}{$id}{'RnlSupportingSector'} =~ /bsc\s(\d+)/);
		my ($lac) = ($cell{$omc}{$id}{'CellGlobalIdentity'} =~ /lac\s(\d+)/);
		$bscConfig{$omc}{$bscid}{"LAC"}{$lac}++;
		$bscConfig{$omc}{$bscid}{"RAC"}{$cell{$omc}{$id}{'ACmbRaCode'}}++ if ($cell{$omc}{$id}{'ACmbRaCode'} > 0);
	}
}


foreach my $omc (keys %emlBsc) {
	foreach my $id (keys %{$emlBsc{$omc}}) {
		my ($bscId) = ($id =~ /amecID\s(\d+)/);
		$bscConfig{$omc}{$bscId}{"NAME"} = $emlBsc{$omc}{$id}{"UserLabel"};
		$bscConfig{$omc}{$bscId}{"GEN"} = $emlBsc{$omc}{$id}{"BSC_Generation"};
		$bscConfig{$omc}{$bscId}{"CONFIG"} = $emlBsc{$omc}{$id}{"BSC_HW_Config"};
		$bscConfig{$omc}{$bscId}{"IMPORTDATE"} = $emlBsc{$omc}{$id}{"IMPORTDATE"};
	}
}
loadACIE("AlcatelX25Link","eml",\%x25);
foreach my $omc (keys %x25) {
	foreach my $id (keys %{$x25{$omc}}) {
		my $type = $x25{$omc}{$id}{"X25LinkType"};
		if ($id =~ /amecID\s\d+, moiRdn\s1/) {
			my ($bscid) = ($id =~ /amecID\s(\d+)/);
			if ($type =~ /bsc/) {
				$bscConfig{$omc}{$bscid}{"BSCX25PRIM"} = $x25{$omc}{$id}{"PrimaryNsap"};
				$bscConfig{$omc}{$bscid}{"BSCX25SEC"} = $x25{$omc}{$id}{"SecondaryNsap"};
			}
			elsif ($type =~/preferredOmc/) {
				$bscConfig{$omc}{$bscid}{"PREFOMCX25PRIM"} = $x25{$omc}{$id}{"PrimaryNsap"};
				$bscConfig{$omc}{$bscid}{"PREFOMCX25SEC"} = $x25{$omc}{$id}{"SecondaryNsap"};
			}
			elsif ($type =~/secondaryOmc/) {
				$bscConfig{$omc}{$bscid}{"SECOMCX25PRIM"} = $x25{$omc}{$id}{"PrimaryNsap"};
				$bscConfig{$omc}{$bscid}{"SECOMCX25SEC"} = $x25{$omc}{$id}{"SecondaryNsap"};
			}	
			elsif ($type =~/cbc/){
				$bscConfig{$omc}{$bscid}{"CBCX25PRIM"} = $x25{$omc}{$id}{"PrimaryNsap"};
				$bscConfig{$omc}{$bscid}{"CBCX25SEC"} = $x25{$omc}{$id}{"SecondaryNsap"};
			}
		}
	}
}

loadACIE("MtpSignPoint","eml",\%mtp);
foreach my $omc (keys %mtp) {
	foreach my $id (keys %{$mtp{$omc}}) {
		$bscConfig{$omc}{$id}{"SPC"} = $mtp{$omc}{$id}{"PointCode"};
	}
}

loadACIE("AlcatelSignLinkSetTp","eml",\%setTp);
foreach my $omc (keys %setTp) {
	foreach my $id (keys %{$setTp{$omc}}) {
		$bscConfig{$omc}{$id}{"MSC_SPC"} = $setTp{$omc}{$id}{"AdjPc"};
	}
}
my %usage = ();
loadACIE("Alcatel2MbTTP","eml",\%ttp);
foreach my $omc (keys %ttp) {
	foreach my $id (keys %{$ttp{$omc}}) {
		if ($id =~ /amecID\s\d+, moiRdn\s1/) {
			if ($ttp{$omc}{$id}{"TTPtype"} =~ /atermux/) {
				if (($ttp{$omc}{$id}{"AdministrativeState"} eq 'unlocked') && ($ttp{$omc}{$id}{"OperationalState"} =~ /enabled/)) {
					my ($bscid) = ($id =~ /amecID\s(\d+)/);
					$bscConfig{$omc}{$bscid}{"CS_HWAY_NO"}++ if ($ttp{$omc}{$id}{"GslUsage"} eq 'FALSE');
					if ($ttp{$omc}{$id}{"GslUsage"} eq 'TRUE') {
						$usage{$omc}{$bscid}{$ttp{$omc}{$id}{"AterMuxGprsUsage"}}++;
						$bscConfig{$omc}{$bscid}{"PS_HWAY_NO"}++;
						$bscConfig{$omc}{$bscid}{"GSL_NO"}++;
						$bscConfig{$omc}{$bscid}{"Usage"} = join(',',keys %{$usage{$omc}{$bscid}});
					}
				}
				if (($ttp{$omc}{$id}{"AdministrativeState"} eq 'locked') && ($ttp{$omc}{$id}{"OperationalState"} =~ /enabled/)) {
					my ($bscid) = ($id =~ /amecID\s(\d+)/);
					$bscConfig{$omc}{$bscid}{"CS_HWAY_NO(LOCKED)"}++ if ($ttp{$omc}{$id}{"GslUsage"} eq 'FALSE');
				}
			}
		}
	}
}
loadACIE("AlcatelSignLinkN7","eml",\%n7);
foreach my $omc (keys %n7) {
	foreach my $id (keys %{$n7{$omc}}) {
		if ($n7{$omc}{$id}{"AdministrativeState"} =~ /unlocked/) {
			my ($bscid) = ($id =~ /amecID\s(\d+)/);
			$bscConfig{$omc}{$bscid}{"N7_NO"}++;
		}
	}
}

#print Dumper(\%bscConfig);
#spool BSC Config CSV output
open(BSC,">".$config{"OUTPUT_CSV"}."bscConfig.csv") || die "Cannot open bscConfig.csv: $!\n";
my @cols = qw /IMPORTDATE NAME GEN CONFIG SPC MSC_SPC CS_HWAY_NO CS_HWAY_NO(LOCKED) N7_NO PS_HWAY_NO GSL_NO Usage MFS_ID MFS_NAME MFS_GEN MFSIPADDRESS BSCIPADDRESS BSCX25PRIM BSCX25SEC PREFOMCX25PRIM PREFOMCX25SEC SECOMCX25PRIM SECOMCX25SEC CBCX25PRIM CBCX25SEC/;
print BSC "OMC_ID;BSC_ID;LACS;RACS;".join(';',@cols)."\n";
foreach my $omc (sort keys %bscConfig) {
	foreach my $bscid (sort keys %{$bscConfig{$omc}}) {
		my $lacs = join('/',sort keys %{$bscConfig{$omc}{$bscid}{"LAC"}});
		my $racs = join('/',sort keys %{$bscConfig{$omc}{$bscid}{"RAC"}});
		print BSC "$omc;$bscid;$lacs;$racs;".join(';',map(defined($_)?$_:'-',@{$bscConfig{$omc}{$bscid}}{@cols}))."\n";
	}
}
close BSC || die "Cannot close bscConfig.csv: $!\n";
print "--END:Compiling BSC Config Information:END--\n";


__END__
