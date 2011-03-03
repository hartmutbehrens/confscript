#!/usr/bin/perl -w

# 2006 by Hartmut Behrens (##)
# Vodacom place DP-INFO in UserMemo of AlcatelManagedElement. This report is just a consolidatiojn of that info.
use strict;
use warnings;
use File::Copy;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";
my $date = '0000-00-00';

my %element = (
	"AlcatelManagedElementInstanceIdentifier"	=>1,			#only load these columns
	"EquipmentType"	=>1,
	"UserLabel"			=>1,
	"UserMemo"			=>1
	);
my %rnlBsc = (
	"RnlAlcatelBSCInstanceIdentifier"	=>1,				#only load these columns
	"IMPORTDATE" => 1,
	"UserLabel"			=>1
	);
my %btsConfig = ();
my %bscConfig = ();
my %abCount = ();
my @cols = ();
my %line = ();
if (-e $config{"OUTPUT_CSV"}."bscConfig.csv") {
	open(BSC,"<".$config{"OUTPUT_CSV"}."bscConfig.csv") || die "Cannot open ".$config{"OUTPUT_CSV"}."bscConfig.csv: $!\n";
	while (<BSC>) {
		chomp;
		if ($. == 1) {				#load header line
			@cols = split(/;/,$_);
		}
		else {
			my @data = split(/;/,$_);
			@line{@cols} = @data;
			my $bsc = $line{'BSC_NAME'};
			$bsc =~ s/\"//g;
			my $cs = $line{'CS_HWAY_NO'};
			my $ps = $line{'PS_HWAY_NO'};
			$bscConfig{$bsc} = $cs." CS / ".$ps." PS";
		}
	}
	close(BSC);
}
else {
	die "Please run bscConfig.pl first !\n";
}
my %seenAbis = ();
if (-e $config{"OUTPUT_CSV"}."btsConfig.csv") {
	open(BTS,"<".$config{"OUTPUT_CSV"}."btsConfig.csv") || die "Cannot open ".$config{"OUTPUT_CSV"}."btsConfig.csv: $!\n";
	while (<BTS>) {
		chomp;
		if ($. == 1) {				#load header line
			@cols = split(/;/,$_);
		}
		else {
			my @data = split(/;/,$_);
			@line{@cols} = @data;
			my $bsc = $line{'BSC_NAME'};
			my $site = $line{'Site_Name'};
			$bsc =~ s/\"//g;
			$site =~ s/\"//g;
			my $abis = $line{'AbisTopology'};
			
			if ($abis =~ /^ring/) {
				$abCount{$bsc} += 2 if not(exists($seenAbis{$bsc}{$abis}));
			}
			elsif ($abis =~ /^chain/) {
				if ($abis =~ /^chain.*?chain/) {
					$abCount{$bsc} += 2 if not(exists($seenAbis{$bsc}{$abis}));
				}
				else {
					$abCount{$bsc} += 1 if not(exists($seenAbis{$bsc}{$abis}));
				}
			}
			$btsConfig{$bsc}{$site} = $abis;
			$seenAbis{$bsc}{$abis}++;
		}
	}
	close(BTS);
}
else {
	die "Please run btsConfig.pl first !\n";
}

print "--Gathering Transmission DP-INFO--\n";
&loadACIE("AlcatelManagedElement","eml",\%element);
&loadACIE("RnlAlcatelBSC","rnl",\%rnlBsc);

open(TRANS,">".$config{"OUTPUT_CSV"}."dpInfo.csv") || die "Cannot open dpInfo.csv file : $!\n";
print TRANS "BSC;BTS;ABIS;HWAY;DP-INFO;\n";
foreach my $omc (keys %element) {
	foreach my $id (sort keys %{$element{$omc}}) {
		my ($bscId) = ($id =~ /.*?(\d+)/);
		$date = $rnlBsc{$omc}{$bscId}{'IMPORTDATE'};
		my $bsc = $rnlBsc{$omc}{$bscId}{'UserLabel'};
		$bsc =~ s/\"//g;
		my ($ab,$hw,$name) = ('-','-','-');
		if ($element{$omc}{$id}{'EquipmentType'} =~ /bsc/) {
			$ab = $abCount{$bsc};
			$hw = $bscConfig{$bsc};
		}
		elsif ($element{$omc}{$id}{'EquipmentType'} =~ /bts/) {
			$name = $element{$omc}{$id}{'UserLabel'};
			$name =~ s/\"//g;
			$ab = $btsConfig{$bsc}{$name} || '';
		}
		else {
			next;
		}
		my $memo = $element{$omc}{$id}{'UserMemo'} || '';
		print TRANS "$bsc;$name;$ab;$hw;$memo\n";
	}
}

close TRANS || die "Cannot close a925.csv: $!\n";
copy($config{"OUTPUT_CSV"}."dpInfo.csv","/var/www/html/confsheets/history/transmissionInfo/dpInfo-".$date.".csv");
print "--END:Gathering Transmission DP-INFO:END--\n";


__END__