#!/usr/bin/perl -w

# 2008 by Hartmut Behrens (##)
use strict;
use warnings;
use DBI;

require "loadACIEsubs.pl";
my $riFile = '../RI/btsRI.csv';
my $lapdFile = 'output/csv/lapdConfig.csv';
my %rep = ();


my @fields = qw(CellInstanceIdentifier CellGlobalIdentity RnlSupportingSector UserLabel AGprsMinPdch AGprsMaxPdch AGprsMaxPdchHighLoad PsPrefBcchTrx EnGprs EnEgprs HoppingType);
my %cell = map {$_ => 1}	@fields;	
my %sector;
	
my %bbt = (
	"AlcatelBasebandTransceiverInstanceIdentifier"	=>1,
	"ChannelSelectionPreferenceMark" => 1,
	"ListOfRadioChannels" => 1,
	"Tei" => 1,
	"TRX" => 1
);
	
my %site = (
	"AlcatelBtsSiteManagerInstanceIdentifier" =>1,
	"UserLabel" => 1
);

my %btsSector = (
	"AlcatelBts_SectorInstanceIdentifier" =>1,
	"NbBaseBandTransceiver" => 1
);

my %bsc = (
	"RnlAlcatelBSCInstanceIdentifier" =>1,
	"UserLabel" => 1
);

my %function = (
	"AlcatelFunctionInstanceIdentifier" => 1,
	"RelatedBtsSector" => 1,
	"RelatedCircuitPackList" => 1,
	"RelatedTRX" => 1
);

my %circuit = (
	"AlcatelCircuitPackInstanceIdentifier" => 1,
	"CircuitPackType" => 1
);

my %hwRank = (
	'taghe' => 1,
	'tadhe' => 1,
	'trage' => 2,
	'tgt09' => 2,
	'trade' => 2,
	'tgt18' => 2,
	'tagh' => 3,
	'tadh' => 3,
	'trag' => 4,
	'trad' => 5,
	'trdh' => 6,
	'trgm' => 7,
	'trdm' => 7
);
	
my %drRank = (
	'fullRate' => 0,
	'multiRate' => 1
);

my %pdchRank = (
	'8' => 0,
	'7' => 1,
	'6' => 2,
	'5' => 3,
	'4' => 4,
	'3' => 5,
	'2' => 6,
	'1' => 7
);

my $dbh;
my $rv = connectMySQL(\$dbh);

loadACIE("Cell","rnl",\%cell);
loadACIE("RnlAlcatelBSC","rnl",\%bsc);
loadACIE("AlcatelBasebandTransceiver","eml",\%bbt);
loadACIE("AlcatelBtsSiteManager","eml",\%site);
loadACIE("AlcatelBts_Sector","eml",\%btsSector);
loadACIE("AlcatelCircuitPack","eml",\%circuit);
loadACIE("AlcatelFunction","eml",\%function);


#read RI data
open BTSRI, '<'.$riFile or die "Cannot open $riFile : $!\n";
my @cols;
my %d = ();
my %ri = ();
while (<BTSRI>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @row = split(/;/,$_);
		@d{@cols} = @row;
		$ri{join(',',@d{qw/BSC_NAME SITE_NAME RACK SHELF SLOT/})} = join(';',@d{qw/SERIAL_NO PART_NO/});
	}
}
close BTSRI;
#read FR/DR config
open IN, '<'.$lapdFile or die "Cannot open $lapdFile : $!\n";
my %e = ();
my %lapd = ();
while (<IN>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @row = split(/;/,$_);
		@e{@cols} = @row;
		next unless ($e{'LapdLinkUsage'} eq 'rsl');
		$e{'UserLabel'} =~ s/\"//g;
		$e{'UserLabel'} =~ s/.*?(\d+)/$1/;
		$lapd{join(',',@e{qw/LAC CI UserLabel/})} = $e{'SpeechCodingRate'};
	}
}
close IN;

my %pdchConfig;
foreach my $omc (keys %cell) {
	foreach my $id (keys %{$cell{$omc}}) {
		my ($bsc,$bts,$sector) = ($cell{$omc}{$id}{'RnlSupportingSector'} =~ /bsc\s(\d+).*?btsRdn\s(\d+).*?sectorRdn\s(\d+)/);
		my $sid = '{{ bsmID { amecID '.$bsc.', moiRdn '.$bts.'}, moiRdn '.$sector.'}}';
		@{$sector{$omc}{$sid}}{@fields} = @{$cell{$omc}{$id}}{@fields};
		my $cgi = $sector{$omc}{$sid}{'CellGlobalIdentity'};
		my ($lac,$ci) = ($cgi =~ /lac\s(\d+).*?ci\s(\d+)/);
		@{$pdchConfig{$lac.';'.$ci}}{qw/minpdch maxpdch/} = @{$sector{$omc}{$sid}}{qw/AGprsMinPdch AGprsMaxPdch/}
	}
}

my %data;
foreach my $omc (keys %function) {
	foreach my $id (keys %{$function{$omc}}) {
		my ($cid,$sid,$tid) = @{$function{$omc}{$id}}{qw/RelatedCircuitPackList RelatedBtsSector RelatedTRX/};
		next if $cid eq '{}';
		$cid =~ s/^\{(.*)\}/$1/;
		$tid =~ s/relatedObject\://;
		if ($tid =~ /notAvailable/) {
			next;
		}
		my ($rack,$shelf,$slot) = ($cid =~ /.*?amecID\s\d+.*?moiRdn\s\d+.*?rackRdn\s(\d+).*?shelfRdn\s(\d+).*?moiRdn\s(\d+).*?/);

		my ($bsc,$bts) = ($sid =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
		(my $bscName = $bsc{$omc}{$bsc}{'UserLabel'}) =~ s/\"//g;
		my ($mark,$tei,$trx,$channels) = @{$bbt{$omc}{$tid}}{qw/ChannelSelectionPreferenceMark Tei TRX ListOfRadioChannels/};
		
		(my $type = $circuit{$omc}{$cid}{'CircuitPackType'}) =~ s/\"//g;
		next if !($type =~ /^t.*?$/);	#only interested in trx's ..
		#print "$omc:$sid:$type:\n";
		(my $sectorName = defined($sector{$omc}{$sid}{'UserLabel'})?$sector{$omc}{$sid}{'UserLabel'}:'-') =~ s/\"//g;
		next if ($sectorName eq '-');		#skip cells with no sector name for now - should look up related bts sector, because these are slave cell's associated with a master
		#print "s:$sectorName:\n";
		my $psPrefMark = $sector{$omc}{$sid}{'PsPrefBcchTrx'};
		

		my $siteId = '{ amecID '.$bsc.', moiRdn '.$bts.'}';
		(my $siteName = $site{$omc}{$siteId}{'UserLabel'}) =~ s/\"//g;
		my $rid = join(',',$bscName,$siteName,$rack,$shelf,$slot);
		$trx =~ s/trx\://;
		my ($cgi,$hop) = @{$sector{$omc}{$sid}}{qw/CellGlobalIdentity HoppingType/};
		my ($lac,$ci) = ($cgi =~ /lac\s(\d+).*?ci\s(\d+)/);
		my $rate = $lapd{join(',',$lac,$ci,$tei)};
		my $ri = exists($ri{$rid}) ? $ri{$rid} : '-';
		my ($prefRank,$pdch) = (1,0);
		$pdch++ while ($channels =~ /tch|dynsd/ig);
		if ($channels =~ /bcc/i) {
			$prefRank = 0 if ($psPrefMark == 1);
			$prefRank = 100 if ($psPrefMark == 2);
		}
		@{$data{$lac.';'.$ci}{$trx}}{qw/psprefmark type rate ri trx tei rack shelf slot site sector bsc hwrank drrank prefrank channel pdchrank pdchts hoptype/} = ($psPrefMark,$type,$rate,$ri,$trx,$tei,$rack,$shelf,$slot,$siteName,$sectorName,$bscName,$hwRank{$type},$drRank{$rate},$prefRank,$channels,$pdchRank{$pdch},$pdch,$hop);
		#print "$bscName : $siteName : $sectorName : $type : $mark : $trx : $tei : $lac : $ci : $rate : $ri\n";
	}
}

my $weekago = date_daysback(7);
my $yesterday = date_daysback(1);
my @trxCol = qw/MC390 MC400 MC621 MC703 MC710 MC712 MC717a MC717b MC718 MC736 MC746b/;
my @celCol = qw/MC15a MC15b MC140a MC140b MC142e MC142f/;
my $sql = 'select 100*( sum(P20e) / ( sum(P20e) + ( ( ( sum(P55e*176)+ sum(P55f*224)+ sum(P55g*296)+ sum(P55h*352))+( sum(P55i*448)+ sum(P55j*592)+ sum(P55k*448)+ sum(P55l*544)+ sum(P55m*592))) / 8)))  from GPM_CELL_D where CI = ? and LAC = ? and SDATE >= ?';
my $sth = $dbh->prepare($sql);
my $sth2 = $dbh->prepare('select CellBarred,RnlCellType from Cell where CI = ? and LAC = ? and IMPORTDATE = ?');
my $sth3 = $dbh->prepare('select '.join(',',map('sum('.$_.')',@celCol)).' from T110_SECTOR_D where CI = ? and LAC = ? and SDATE >= ?');
my $sth4 = $dbh->prepare('select '.join(',',map('sum('.$_.')',@trxCol)).' from T110_TRX_D where CI = ? and LAC = ? and TRX = ? and SDATE >= ?');

open(OUT,'>trxRep.'.$weekago.'-'.$yesterday.'.csv') || die "Cannot open trxRep.csv. Error is :$!\n";
open(DEG,'>degradedtrxRep.'.$weekago.'-'.$yesterday.'.csv') || die "Cannot open degradedtrxRep.csv. Error is :$!\n";
print OUT "DATE;LAC;CI;BSC;SITENAME;CELLNAME;MNEMONIC;TRX;TRE;HOPPINGTYPE;MINPDCH;MAXPDCH;MCSx_RETRANS_RATE;PROFILE;RACK;SHELF;SLOT;SERIAL_NO;PART_NO\n";
print DEG "DATE;LAC;CI;BSC;SITENAME;CELLNAME;MNEMONIC;TRX;TRE;HOPPINGTYPE;BAR_STATUS;SDCCH_MHT;RTCH_DROP_RATE;RTCH_ASSIGN_EFF_RATE;RTCH_HO_EFF_RATE;RTCH_ASSIGN_ALLOC;RTCH_HO_ALLOC;MCSx_RETRANS_RATE;PROFILE;RACK;SHELF;SLOT;SERIAL_NO;PART_NO\n";
foreach my $laci (keys %data) {
	my ($lac,$ci) = split(';',$laci);
	my %d = ();
	$sth2->execute($ci,$lac,$yesterday);
	my ($barred,$cellType) = $sth2->fetchrow_array;
	next if ($cellType =~ /extended/);
	$sth->execute($ci,$lac,$weekago);
	$sth3->execute($ci,$lac,$weekago);
	my ($val) = $sth->fetchrow_array;
	@d{@celCol} = $sth3->fetchrow_array;
	$d{'MC924c'} = 0;									#not loaded into database yet - so set to 0
	my $mcsRate = defined($val)? sprintf("%.2f",$val) : '-';
	
	#sort according to packet trx ranking algorithm, skip e-gsm criterion as it is not applicable in Vod RSA.
	my @trx = sort {$data{$laci}{$a}{'prefrank'} <=> $data{$laci}{$b}{'prefrank'} 
		|| $data{$laci}{$a}{'hwrank'} <=> $data{$laci}{$b}{'hwrank'}
		|| $data{$laci}{$a}{'drrank'} <=> $data{$laci}{$b}{'drrank'}
		|| $data{$laci}{$a}{'pdchrank'} <=> $data{$laci}{$b}{'pdchrank'}
		|| $a <=> $b} keys %{$data{$laci}};
	#print "$laci : @trx\n";
	my %id;
	my ($minpdch,$maxpdch) = @{$pdchConfig{$laci}}{qw/minpdch maxpdch/};
	my $i = 1;
	for my $trx (@trx) {
		next unless ($data{$laci}{$trx}{'ri'} =~ /AAAA/);
		if ($data{$laci}{$trx}{'type'} =~ /e/) {
			$sth4->execute($ci,$lac,$trx,$weekago);
			@d{@trxCol} = $sth4->fetchrow_array;
			my ($rt_ass_fail_rate, $cd_radio_rate, $sd_mht, $trx_rt_drop_rate, $trx_rt_ass_eff_rate, $trx_rt_ho_eff_rate) = (0,0,0,0,0,0);
			#avoid division by zero errors
			my $den1 = ($d{'MC140a'} - ($d{'MC142e'}+$d{'MC142f'})) || 1;
			my $den2 = ($d{'MC718'}+$d{'MC717a'} + $d{'MC717b'} - ($d{'MC712'}+$d{'MC924c'})) || 1;
			my $den3 = ($d{'MC718'}+$d{'MC717a'} + $d{'MC717b'}) || 1;
			#$rt_ass_fail_rate = ($d{'MC746b'} + ($d{'MC140b'} - $d{'MC718'} - $d{'MC746b'})) / $den1;
			#$cd_radio_rate = $d{'MC736'} / $den2;
			my $degraded = 'no';
			if ($barred eq 'FALSE') {
				$sd_mht = $d{'MC390'} > 0 ? ($d{'MC400'} / $d{'MC390'}) : 0;
				$trx_rt_drop_rate = $d{'MC736'}/$den3;
				$trx_rt_ass_eff_rate = $d{'MC703'} > 0 ? ($d{'MC718'}/$d{'MC703'}) : 0;
				if ($d{'MC703'} > 50) {
					if (($trx_rt_drop_rate > 0.05) || ($trx_rt_ass_eff_rate < 0.92) || ($sd_mht > 100000)) {
						print DEG join(';',$yesterday,$laci,@{$data{$laci}{$trx}}{qw/bsc site sector type trx tei hoptype/},$barred,sprintf("%.2f",$sd_mht),sprintf("%.2f",$trx_rt_drop_rate),sprintf("%.2f",$trx_rt_ass_eff_rate),'-',$d{'MC703'},($d{'MC15a'}+$d{'MC15b'}),$mcsRate,join('-',sort keys %{$id{$trx}}),@{$data{$laci}{$trx}}{qw/rack shelf slot ri/})."\n";
					}
				}
			}
			else {
				$trx_rt_ho_eff_rate = ($d{'MC717a'}+$d{'MC717b'}) / $den3;
				if (($d{'MC15a'}+$d{'MC15b'}) > 50) {
					if (($trx_rt_ho_eff_rate < 0.93) && ($trx_rt_ho_eff_rate > 0.001)) {
						print DEG join(';',$yesterday,$laci,@{$data{$laci}{$trx}}{qw/bsc site sector type trx tei hoptype/},$barred,'-','-','-',sprintf("%.2f",$trx_rt_ho_eff_rate),$d{'MC703'},($d{'MC15a'}+$d{'MC15b'}),$mcsRate,join('-',sort keys %{$id{$trx}}),@{$data{$laci}{$trx}}{qw/rack shelf slot ri/})."\n";
					}
				}
			}
		
			for (1..$data{$laci}{$trx}{'pdchts'}) {
				$id{$trx}{'PS'}++ if ($i <= $maxpdch);
				$id{$trx}{'CS'}++ if ($i > $minpdch);
				$i++;
			}
			print OUT join(';',$yesterday,$laci,@{$data{$laci}{$trx}}{qw/bsc site sector type trx tei hoptype/},$minpdch,$maxpdch,$mcsRate,join('-',sort keys %{$id{$trx}}),@{$data{$laci}{$trx}}{qw/rack shelf slot ri/})."\n";
		}
	}
}
close OUT;
close DEG;

sub connectMySQL {
	my ($dbhref) = @_;
	
	my $dsn = 'DBI:mysql:;host=localhost;port=3306';
	my $dbh = DBI->connect($dsn, 'tools', 'alcatel');
	my $drh = DBI->install_driver('mysql');
	# grab general database information
	my @databases = map(lc($_),@{$dbh->selectcol_arrayref("show databases")});
	if (! (grep {/alcatelRSA/i} @databases)) {
		return undef;
	}
	# if we are past this point then the database exists and it is possible to connect properly
	$dbh->disconnect;
	$dsn = 'DBI:mysql:alcatelRSA;host=localhost;port=3306';
	$$dbhref = DBI->connect($dsn, 'tools', 'alcatel');
	$drh = DBI->install_driver('mysql');
	return (1);
}


sub date_daysback {
	my ($DaysBack) = @_;
	$DaysBack = 1 if not defined $DaysBack;
	my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime(time - (3600 * 24 * ($DaysBack)));
	$year += 1900;
	$mon++;
	return (sprintf ("%04d-%02d-%02d",$year,$mon,$mday));
}




sub region {
	my ($n) = @_;
	my %na = (
		'W'	=> 'WESTERN',
		'E' => 'EASTERN',
		'C' => 'CENTRAL'
		);
		return $na{substr($n,0,1)}
}


__END__
