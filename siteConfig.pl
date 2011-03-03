#!/usr/bin/perl -w

# 2003 by Hartmut Behrens (##)
use strict;
use warnings;
use File::Copy;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";

my $sitePath = "/var/www/html/confsheets/history/site_count/";

my %circ = ();
my %site = ();
my %cell = ();
my @radio_types = ();
#get linking info from RNL level to EML level from RNL Cell Table
my %btsSector = (
	"AlcatelBts_SectorInstanceIdentifier"	=>1,
	"LocationName"				=>1
	);

print "--Generating Site Count Report--\n";
&loadACIE("AlcatelBts_Sector","eml",\%btsSector);
foreach my $omc (keys %btsSector) {
	foreach my $id (keys %{$btsSector{$omc}}) {
		my $loc = $btsSector{$omc}{$id}{"LocationName"};
		&process_emlsector($id,$omc,$loc);
	}
}

my %circuit = (
		"AlcatelCircuitPackInstanceIdentifier"	=>1,			#only load these columns
		"BtsSector"				=>1,
		"CircuitPackType"			=>1,
		"SlotNumber"				=>1,
		"SupportedByObjectList"			=>1,
		"IMPORTDATE"				=>1
		);
&loadACIE("AlcatelCircuitPack","eml",\%circuit);
my %BTS = ();
my $date = "0000-00-00";
foreach my $omc (keys %circuit) {
	#next if ($omc == 2);
	foreach my $id (keys %{$circuit{$omc}}) {
		my ($moiRdn) = ($id =~ /.*?amecID\s\d+.*?moiRdn\s(\d+).*?/);
		next if ($moiRdn == 1);						#BSC - exclude from rack count
		my $type = $circuit{$omc}{$id}{"CircuitPackType"};
		$date = $circuit{$omc}{$id}{"IMPORTDATE"};
		$type =~ s/\"//g;
		next if ($type =~ /.*?tmag.*?/);
		my $suppObj = $circuit{$omc}{$id}{"SupportedByObjectList"};
		next if ($suppObj =~ /.*?\{\}.*?/);
		my $sector = $circuit{$omc}{$id}{"BtsSector"};
		if ($sector eq 'undefined') {
			$sector = '4';
		}
		my ($bsc,$bts,$rack);
		($bsc) = ($suppObj =~ /.*?amecID\s(\d+).*?/);
		($bts) = ($suppObj =~ /.*?moiRdn\s(\d+).*?/);
		#gather microcell info
		#print "$suppObj : $omc : $bsc : $bts : $type\n";
		#if ($sector =~ /.*?station.*?/) {
			if ($type eq 'mb4g') {
				$BTS{$omc}{$bsc}{$bts}{"MB4G"}++;
				#$BTS{$omc}{$bsc}{$bts}{"RACK_COUNT"}++;
			}
			if ($type eq 'db4g') {
				$BTS{$omc}{$bsc}{$bts}{"DB4G"}++;
				#$BTS{$omc}{$bsc}{$bts}{"RACK_COUNT"}++;
			}
			if ($type eq 'db5e') {
				#print "$suppObj eq db5e\n";
				$BTS{$omc}{$bsc}{$bts}{"DB5E"}++;
				#$BTS{$omc}{$bsc}{$bts}{"RACK_COUNT"}++;
			}
			if ($type eq 'mb5e') {
				$BTS{$omc}{$bsc}{$bts}{"MB5E"}++;
				#$BTS{$omc}{$bsc}{$bts}{"RACK_COUNT"}++;
			}
		#}
		#get distinct amount of racks per SupportedByObjectList
		($rack) = ($id =~ /.*?rackRdn\s(\d+).*?/);
		$circ{$omc}{$suppObj}{$rack} = 1;
		
	}
}

print "Retrieving BTS info\n";
open(BTS,"<".$config{"OUTPUT_CSV"}."btsConfig.csv") || die "Cannot open btsConfig.csv: $!\n";
my @cols;
my %line = ();
my %siteCount = ();
my %seen = ();
while (<BTS>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
		#get radio types
		foreach my $col (@cols) {
			push(@radio_types,$col) if ($col =~/^t[r|x|a|g].*?/);
		}
		#print "Radio types are @radio_types\n";
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		
		my $omc = $line{"OMC"};
		
		my $bsc = $line{"BSC_ID"};
		my $bscName = $line{"BSC_NAME"};
		$bscName =~ s/\"//g;
		my $btsId = $line{"BTS_ID"};
		my $gen = $line{"BTS_GENERATION"};
		my $site = $line{"SITE_NAME"};
		my $beforeSite = $site;
		$site =~ s/\"//g;
		$site =~ s/\d+-(\w+)/$1/;
		
		while ($site =~ /(.*?)(_\d+$)/g) {
			$site = $1;
		}
		my $suppObj = '{{ amecID '.$bsc.', moiRdn '.$btsId.'}}';
		my $rack_count = scalar keys %{$circ{$omc}{$suppObj}};
		#get micro-cell info
		my $db4g = 0;
		my $mb4g = 0;
		my $db5e = 0;
		my $mb5e = 0;
		#print "$site : $omc : $bsc : $btsId\n";
		if (($gen eq 'evolium:a910') || ($gen eq 'evolium:micro')) {
			$db4g = $BTS{$omc}{$bsc}{$btsId}{"DB4G"} || '0';
			$mb4g = $BTS{$omc}{$bsc}{$btsId}{"MB4G"} || '0';
			$db5e = $BTS{$omc}{$bsc}{$btsId}{"DB5E"} || '0';
			$mb5e = $BTS{$omc}{$bsc}{$btsId}{"MB5E"} || '0';
			#$rack_count = $BTS{$omc}{$bsc}{$btsId}{"RACK_COUNT"};
		}
		#init
		$siteCount{$omc}{$bsc}{$site}{'RACK_COUNT'} = 0 if not defined($siteCount{$omc}{$bsc}{$site}{'RACK_COUNT'});
		$rack_count = 0 if not defined($rack_count);
		#combine counts
		my $anx = $line{"ANX_COUNT"} || 0;
		my $any = $line{"ANY_COUNT"} || 0;
		my $anc = $line{"ANC_COUNT"} || 0;
		$anx = 0 if ($anx eq '-');
		$any = 0 if ($any eq '-');
		$anc = 0 if ($anc eq '-');
		foreach my $type (@radio_types) {
			$siteCount{$omc}{$bsc}{$site}{$type} += $line{$type};
		}
		
		$siteCount{$omc}{$bsc}{$site}{"ANC_Count"} += $anc;
		$siteCount{$omc}{$bsc}{$site}{"ANX_Count"} += $anx;
		$siteCount{$omc}{$bsc}{$site}{"ANY_Count"} += $any;
		$siteCount{$omc}{$bsc}{$site}{"SUMA"} = 0 if not exists($siteCount{$omc}{$bsc}{$site}{"SUMA"});
		$siteCount{$omc}{$bsc}{$site}{"SUMP"} = 0 if not exists($siteCount{$omc}{$bsc}{$site}{"SUMP"});
		$siteCount{$omc}{$bsc}{$site}{"GEN"} = $gen;
		$siteCount{$omc}{$bsc}{$site}{"DB4G"} = $db4g;
		$siteCount{$omc}{$bsc}{$site}{"MB4G"} = $mb4g;
		$siteCount{$omc}{$bsc}{$site}{"DB5E"} = $db5e;
		$siteCount{$omc}{$bsc}{$site}{"MB5E"} = $mb5e;
		$siteCount{$omc}{$bsc}{$site}{'RACK_COUNT'} += $rack_count if not exists($seen{$omc}{$bsc}{$beforeSite});
		$siteCount{$omc}{$bsc}{$site}{'BSC'} = $bscName;
		$siteCount{$omc}{$bsc}{$site}{'BTS_ID'} = $btsId;
		
		if ($line{"CONTROL"} =~ /suma/) {
			next if exists($seen{$omc}{$bsc}{$beforeSite});
			$siteCount{$omc}{$bsc}{$site}{"SUMA"}++;
		}
		elsif ($line{"CONTROL"} =~ /sump/) {
			next if exists($seen{$omc}{$bsc}{$beforeSite});
			$siteCount{$omc}{$bsc}{$site}{"SUMP"}++;
		}
		foreach my $loc (keys %{$cell{$omc}{$suppObj}}) {
			next if exists($seen{$omc}{$bsc}{$beforeSite});
			push(@{$siteCount{$omc}{$bsc}{$site}{'locations'}}, $loc);
		}
		$seen{$omc}{$bsc}{$beforeSite} = 1;
	}
}
close BTS || die "Cannot close btsConfig.csv: $!\n";
print "END: Retrieving BTS info\n";
#my $file = "site_count_".$date.".csv";
my $file = "site_count";
open(BTSHW,">".$config{"OUTPUT_CSV"}.$file.".csv") || die "Cannot open ".$config{"OUTPUT_CSV"}."$file.csv : $!\n";
#print BTSHW "OMC;BSC_Name;BTS_Site_Name;BTS_Generation;MB4G_Count;DB4G_Count;DB5E_Count;MB5E_Count;Amount_of_Racks;Rack1_Location;Rack2_Location;Rack3_Location;Rack4_Location;TRGM_Amount;TRAG_Amount;TRDM_Amount;TXGM_Amount;TXGH_Amount;TRAD_Amount;TRDH_Amount;TAGH_Amount;TADH_Amount;TRE_TOTAL;ANC_Amount;ANX_Amount;ANY_Amount;SUMA_Amount;SUMP_Amount;DRFU_Amount\n";
print BTSHW "OMC;BSC_ID;BSC_Name;BTS_ID;BTS_Site_Name;BTS_Generation;MB4G_Count;DB4G_Count;DB5E_Count;MB5E_Count;Amount_of_Racks;Rack1_Location;Rack2_Location;Rack3_Location;Rack4_Location;".join(';',@radio_types).";TRE_TOTAL;ANC_Amount;ANX_Amount;ANY_Amount;SUMA_Amount;SUMP_Amount\n";
foreach my $omc (sort keys %siteCount) {
	foreach my $bsc (sort keys %{$siteCount{$omc}}) {
		foreach my $name (sort keys %{$siteCount{$omc}{$bsc}}) {
			my $bscName = $siteCount{$omc}{$bsc}{$name}{'BSC'};
			my $btsId = $siteCount{$omc}{$bsc}{$name}{'BTS_ID'};
			my $tre_total = 0;
			my @quants = ();
			foreach my $radio (@radio_types) {
				push(@quants,$siteCount{$omc}{$bsc}{$name}{$radio});
				$tre_total += $siteCount{$omc}{$bsc}{$name}{$radio};
			}
			#print "Quants are @quants\n";
			
			my $anc = $siteCount{$omc}{$bsc}{$name}{'ANC_Count'};
			my $anx = $siteCount{$omc}{$bsc}{$name}{'ANX_Count'};
			my $any = $siteCount{$omc}{$bsc}{$name}{'ANY_Count'};
			my $suma = $siteCount{$omc}{$bsc}{$name}{'SUMA'};
			my $sump = $siteCount{$omc}{$bsc}{$name}{'SUMP'};
			my $type = $siteCount{$omc}{$bsc}{$name}{'GEN'};
			my $db4 = $siteCount{$omc}{$bsc}{$name}{'DB4G'};
			my $db5 = $siteCount{$omc}{$bsc}{$name}{'DB5E'};
			my $mb4 = $siteCount{$omc}{$bsc}{$name}{'MB4G'};
			my $mb5 = $siteCount{$omc}{$bsc}{$name}{'MB5E'};
			my $count = $siteCount{$omc}{$bsc}{$name}{'RACK_COUNT'};
			my @locs = ();
			if (defined(@{$siteCount{$omc}{$bsc}{$name}{'locations'}})) {
				@locs =  @{$siteCount{$omc}{$bsc}{$name}{'locations'}};
			}
			$siteCount{$omc}{$bsc}{$name}{'rack1'} = "";
			$siteCount{$omc}{$bsc}{$name}{'rack2'} = "";
			$siteCount{$omc}{$bsc}{$name}{'rack3'} = "";
			$siteCount{$omc}{$bsc}{$name}{'rack4'} = "";
			
			my $loc_count = 1;
			foreach my $loc (@locs) {
				$siteCount{$omc}{$bsc}{$name}{'rack'.$loc_count} = $loc;
				last if ($count == $loc_count);
				$loc_count++;
			}
			#print BTSHW "$omc;$bscName;$name;$type;$mb4;$db4;$db5;$mb5;$count;$siteCount{$omc}{$bsc}{$name}{'rack1'};$siteCount{$omc}{$bsc}{$name}{'rack2'};$siteCount{$omc}{$bsc}{$name}{'rack3'};$siteCount{$omc}{$bsc}{$name}{'rack4'};$trgm;$trag;$trdm;$txgm;$txgh;$trad;$trdh;$tagh;$tadh;$tre_total;$anc;$anx;$any;$suma;$sump;$drfu\n";
			print BTSHW "$omc;$bsc;$bscName;$btsId;$name;$type;$mb4;$db4;$db5;$mb5;$count;$siteCount{$omc}{$bsc}{$name}{'rack1'};$siteCount{$omc}{$bsc}{$name}{'rack2'};$siteCount{$omc}{$bsc}{$name}{'rack3'};$siteCount{$omc}{$bsc}{$name}{'rack4'};".join(';',@quants).";$tre_total;$anc;$anx;$any;$suma;$sump\n";
		}
	}
}
close(BTSHW) || die "Cannot close $file : $!\n";
copy($config{"OUTPUT_CSV"}.$file.".csv",$sitePath.$file."_$date".".csv");
print "--END:Generating Site Count Report:END--\n";
sub process_emlsector {
	my ($id,$omc,$loc) = @_;
	my $bsc = 0;my $bts = 0;
	my $pattern = ".*?amecID\\s(\\d+),\\smoiRdn\\s(\\d+)},\\smoiRdn\\s\\d+}";
	while ($id =~ /$pattern/g) {
		$bsc = $1;
		$bts = $2;
	}
	my $slist	= '{{ amecID '.$bsc.', moiRdn '.$bts.'}}';
	$cell{$omc}{$slist}{$loc}++;
}


__END__