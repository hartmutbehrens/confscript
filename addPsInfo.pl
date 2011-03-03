#!/usr/bin/perl -w

# 2005 by Hartmut Behrens (##)
# Add EDGE Pool info to TCU mapping (rslConfig.csv)

use strict;
use warnings;


require "subs.pl";
require "loadACIEsubs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
my %config = %{$href};
my %rslConfig = ();
my %psConfig = ();
my @cols = ();
my %line = ();
die "Run btsConfig.pl before running this script !\n" unless (-e $config{"OUTPUT_CSV"}."rslConfig.csv");
print "Adding pool TS info to TCU mapping\n\n";
open(RSLCONF,"<".$config{"OUTPUT_CSV"}."rslConfig.csv") || die "Could not open rlsConfig.csv : $!\n";
while (<RSLCONF>) {
	chomp;
	if ($. == 1) {
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		$rslConfig{$line{'OMC_ID'}}{$line{'BSC_ID'}}{$line{'TSU'}}{$line{'TCU'}}{'POOL_USABLE'} = $line{'POOL_USABLE'};
		$rslConfig{$line{'OMC_ID'}}{$line{'BSC_ID'}}{$line{'TSU'}}{$line{'TCU'}}{'RSL_NUM'} = $line{'RSL_NO'};
	}
}
close(RSLCONF);
open(PSCONF,"<".$config{"OUTPUT_CSV"}."psConfig.csv") || die "Could not open psConfig.csv : $!\n";
while (<PSCONF>) {
	chomp;
	next if ($. == 1);
	my @data = split(/;/,$_);
	$psConfig{$data[0]}{$data[1]}{$data[2]} = $data[3];
}
close(PSCONF);

#now go through each TSU of each BSC
open(TCUMAP,">".$config{"OUTPUT_CSV"}."poolConfig.csv") || die "Could not open poolConfig.csv : $!\n";
print TCUMAP "OMC_ID;BSC_ID;TSU;TCU;POOL_TS\n";
foreach my $omc (keys %rslConfig) {
	#next if ($omc == 2);
	foreach my $bsc (keys %{$rslConfig{$omc}}) {
		#next if ($bsc != 6);
		#print "BSC\t$bsc\n\n";
		foreach my $tsu (keys %{$rslConfig{$omc}{$bsc}}) {
			#next if ($tsu != 1);
			#print "\tTSU\t$tsu\n\n";
			my $poolTs = defined($psConfig{$omc}{$bsc}{$tsu}) ? $psConfig{$omc}{$bsc}{$tsu} : 0;
			#next if ($poolTs == 0);			#nothing to assign
			my $assignedAll = 0;
			#first search for hollow TCU's from 8 - 1 and assign Pool TS accordingly.
			
			foreach my $tcu (sort {$b <=>$a} keys %{$rslConfig{$omc}{$bsc}{$tsu}}) {
				$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_TS'} = 0 if not defined($rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_TS'});
				my $poolUsable = $rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_USABLE'};
				next if ($poolUsable eq 'NO');
				next if ($rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'RSL_NUM'} == 4);
				while (($rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'RSL_NUM'} < 4) && ($poolTs > 0) && ($rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'RSL_NUM'} > 0)) {	#now assign pool TS.
					$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_TS'}++;
					#print "H: TCU $tcu :  Pool TS",$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_TS'},"\n";
					$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'RSL_NUM'} += 0.5;
					#$rslNum = int($rslNum);
					$poolTs--;
				}
				
			}
			$assignedAll = 1 if ($poolTs == 0);
			#thereafter check the empty TCU's  from 8 - 1 and assign pool TS accordingly.
			if ($assignedAll == 0) {
				#print "Now checking for empty TCU's...\n";
				foreach my $tcu (sort {$b <=>$a} keys %{$rslConfig{$omc}{$bsc}{$tsu}}) {
					my $poolUsable = $rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_USABLE'};
					next if ($poolUsable eq 'NO');
					next if ($rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'RSL_NUM'} == 4);
					while (($rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'RSL_NUM'} < 4) && ($poolTs > 0)) {	#now assign pool TS.
						$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_TS'}++;
						#print "E: TCU $tcu :  Pool TS",$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_TS'},"\n";
						$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'RSL_NUM'} += 0.5;
						$poolTs--;
					}
				}
			}
			#print to file
			foreach my $tcu (sort {$b <=>$a} keys %{$rslConfig{$omc}{$bsc}{$tsu}}) {
				print TCUMAP "$omc;$bsc;$tsu;$tcu;".$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_TS'}."\n";
				#print "\t\tTCU\t$tcu\tPool TS\t",$rslConfig{$omc}{$bsc}{$tsu}{$tcu}{'POOL_TS'},"\n";
			}
			#print "\n";
		}	
	}
}
close TCUMAP;
print "Finished adding pool TS info to TCU mapping\n";

__END__
