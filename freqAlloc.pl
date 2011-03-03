#!/usr/bin/perl -w
# 2004 by Hartmut Behrens (##)
# compile Frequency Allocation, Radio Channel allocation info

use strict;
use warnings;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";
my @fields = qw(CellInstanceIdentifier CellAllocation CellAllocationDCS CellGlobalIdentity RnlSupportingSector UserLabel HoppingType );
my %rnlCell = map {$_ => 1}	@fields;
my %rnlBbt = (
	"RnlBasebandTransceiverInstanceIdentifier"	=>1,
	"ListOfRadioChannels"				=>1
	);

my %rnlBsc = (
	"RnlAlcatelBSCInstanceIdentifier"	=>1,
	"UserLabel"				=>1
	);
	
print "--Compiling Cell Allocation, TRX TS Configuration--\n";
&loadACIE("Cell","rnl",\%rnlCell);
&loadACIE("RnlBasebandTransceiver","rnl",\%rnlBbt);
&loadACIE("RnlAlcatelBSC","rnl",\%rnlBsc);

open(TRX,">".$config{"OUTPUT_CSV"}."trxConfig.csv") || die "Cannot open trxConfig.csv: $!\n";
print TRX "BSC;CELLNAME;LAC;CI;TRX;CellAllocation;CellAllocationDCS;HoppingType;ChannelConfiguration\n";
foreach my $omc (keys %rnlBbt) {
	foreach my $id (keys %{$rnlBbt{$omc}}) {
		my $channel = $rnlBbt{$omc}{$id}{"ListOfRadioChannels"};
		my ($cellId,$trx) = ($id =~ /.*?(\{\sapp.*?\}).*?bbtRdn\s(\d+)\}/);
		my (undef,$ca,$caDCS,$globalId,$sector,$cellName,$hopType) = @{$rnlCell{$omc}{$cellId}}{@fields};
		my ($lac,$ci) = ($globalId =~ /.*?lac\s(\d+).*?ci\s(\d+).*?/);
		my ($bscId) = ($sector =~ /.*?bsc\s(\d+).*?/);
		(my $bscName = $rnlBsc{$omc}{$bscId}{"UserLabel"}) =~ s/\"//g;
		$cellName =~ s/\"//g;
		print TRX "$bscName;$cellName;$lac;$ci;$trx;$ca;$caDCS;$hopType;$channel\n";
	}
}
close TRX;
print "--END:Compiling Cell Allocation, TRX TS Configuration:END--\n";