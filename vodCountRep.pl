#!/usr/bin/perl -w

# 2005 by Hartmut Behrens (##)
use strict;
use warnings;
use CGI qw(-no_debug :standard :html3 *table);
use File::Copy;
use Net::FTP;
use DBI;


use constant VERSION			=> "1.0";
use constant FTP => 1;
# HTML settings
use constant CLR_BG_TH			=> "#dcdcdc";
use constant CLR_BG_TD			=> "#FFFFFF"; 
use constant CLR_BG_TD_ARG		=> "#e0ffff";
use constant CLR_FONT			=> "#000000";
use constant CLR_RED			=> "#FF9999";
use constant CLR_BRIGHT_RED		=> "#FF0000";
use constant CLR_BLUE			=> "#AFEEEE";
use constant CLR_YELLOW			=> "#FFFF00";
use constant CLR_ORANGE			=> "#FFDD00";
use constant CLR_GREEN			=> "#98FB98";
use constant CLR_BG			=> "#77ccff";
use constant CLR_D_BAD_CNT		=> "#ff0000";
use constant CLR_D_QUESTIONS		=> "#ffff00";
use constant CLR_D_STUCK		=> "#ffa500";
use constant CLR_D_PRESENT		=> "#90ee90";
use constant CLR_D_EMPTY		=> "#d3d3d3";
use constant TABLE_WIDTH		=> 780;
use constant CELL_NAME_SIZE		=> 18;



my $style = 	"p {font-size: 75%; font-family: sans-serif; text-align: center}\n".
				"h2 {font-family: sans-serif; font: italic; text-align: center}\n".
				"h3 {font-family: sans-serif; font: italic; text-align: center}\n".
				"th {background: ".(CLR_BG_TH)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif}\n".
				"td {background-color: ".(CLR_BG_TD)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif; text-align: center}\n".
				"td.blank {background: transparent;}\n".
				"td.etcu {background-color: ".(CLR_GREEN).";}\n".
				"td.mrate {background-color: ".(CLR_BLUE).";}\n".
				"td.hrProb {background-color: ".(CLR_YELLOW).";}\n".
				"td.pkt {background-color: ".(CLR_ORANGE).";}\n".
				"td.sdhigh {color: ".(CLR_BRIGHT_RED)."; font: bold;}\n".
				"td.sdhighmrate {background-color: ".(CLR_BLUE)."; color: ".(CLR_BRIGHT_RED)."; font: bold;}\n".
				"td.mtrx {background-color: ".(CLR_RED).";}\n".
				"table.cl {width: \"100%\"; border: 0; cellspacing: 0; cellpadding: 0}\n".
				"caption {font-family: sans-serif; font: bold italic; font-size: 75%; text-align: center}\n";




my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";
my %rep = ();
my %excl = ();
my %celRep = ();
my %seen = ();
my $date = '0000-00-00';
my $dbh = undef;
die("Could not connect to database. Please check settings !\n") unless (connectDB(\$dbh));
my $cref = getSites();


my %bSct = (
	"AlcatelBts_SectorInstanceIdentifier"	=>1,
	"FrequencyRange"				=> 1,
	"BCCHFrequency"					=> 1,
	"CellGlobalIdentity"		=> 1,
	"NbBaseBandTransceiver" => 1,
	"CELL_DIMENSION_TYPE"		=> 1,
	"UserLabel"							=> 1,
	"GprsCapability"				=> 1,
	"EnGprs"								=> 1,
	"EnEgprs"								=> 1,
	"MaxGprsCs"							=> 1,
	"ACmbNExtraAbisTsMain"			=> 1
	);
	
my %cell = (
	"CellInstanceIdentifier" => 1,
	"AGprsMinPdch" => 1,
	"EnGprs" => 1,
	"EnEgprs" => 1,
	"ACmbNbExtraAbisTs" => 1
	);
	
my %site = (
	"AlcatelBtsSiteManagerInstanceIdentifier" => 1,
	"BTS_Generation"	=> 1,
	"UserLabel" => 1
	);

my %bsc = (
	"RnlAlcatelBSCInstanceIdentifier" => 1,
	"RnlRelatedMFS"	=> 1,
	"IMPORTDATE" => 1,
	"UserLabel" => 1
	);

my %circ = (
		"AlcatelCircuitPackInstanceIdentifier"	=>1,			#only load these columns
		"CircuitPackType"			=>1,
		"AdministrativeState"				=>1,
		);


my %BTS = ();
loadACIE("AlcatelBtsSiteManager","eml",\%site);
loadACIE("AlcatelBts_Sector","eml",\%bSct);
loadACIE("RnlAlcatelBSC","rnl",\%bsc);
loadACIE("AlcatelCircuitPack","eml",\%circ);
my %hasTra = ();
my @cols;
my %line = ();
my %mType = ();
print "Retrieving BTS Config\n";
open(SITE,"<".$config{"OUTPUT_CSV"}."btsConfig.csv") || die "Cannot open btsConfig.csv: $!\n";
while (<SITE>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		$hasTra{$line{"CI"}} = $line{"TRA_EQUIPPED"};
		$mType{$line{"CI"}} = $line{"uBTS"};
	}
}
close(SITE);
print "END:Retrieving BTS Config\n";

foreach my $omc (keys %bsc) {
	foreach my $bsc (keys %{$bsc{$omc}}) {
		my $bscN = $bsc{$omc}{$bsc}{'UserLabel'};
		$date = $bsc{$omc}{$bsc}{'IMPORTDATE'};
		next if not(defined($bscN));
		$bscN =~ s/\"//g;
		my $rg = region($bscN);
		$celRep{$rg}{'BSCs'}++;
	}
}

foreach my $omc (keys %site) {
	foreach my $id (keys %{$site{$omc}}) {
		my $excl = 0;
		my $bts_hw = $site{$omc}{$id}{'BTS_Generation'} || $site{$omc}{$id}{'BtwHwFamily'};
		my $type = ($bts_hw =~ /micro/) ? 'MICRO BTSs' : ($bts_hw =~ /evolium$/) ? 'MICRO BTSs' : 'MACRO BTSs';
		my $n = $site{$omc}{$id}{'UserLabel'};
		$n =~ s/\"//g;
		$excl = 1 if (($n =~ /_mobile$/i) || ($n =~ /_new$/i) || ($n =~ /_test$/i));
		my ($bsc,$bts) = ($id =~ /amecID\s(\d+).*?moiRdn\s(\d+)/);
		my $bscN = $bsc{$omc}{$bsc}{'UserLabel'};
		next if not(defined($bscN));
		$bscN =~ s/\"//g;
		my $rg = region($bscN);
		
		$seen{$bscN}{$n} = 1;
		my ($has900,$has1800,$gprsBts,$edgeBts) = (0,0,0,0);
		for (1..8) {
			my $sect = "{ bsmID ".$id.", moiRdn ".$_."}";
			if (exists($bSct{$omc}{$sect})) {
				my $dim = ($bts_hw =~ /micro/) ? 'MICROCELL' : 'MACROCELL';
				my $canGprs = $bSct{$omc}{$sect}{'GprsCapability'};		
				my $enGprs = $bSct{$omc}{$sect}{'EnGprs'};
				my $enEgprs = $bSct{$omc}{$sect}{'EnEgprs'};
				my $cs = $bSct{$omc}{$sect}{'MaxGprsCs'};
				#my $poolTs = $bSct{$omc}{$sect}{'ACmbNbExtraAbisTs'};
				my $poolTs = $bSct{$omc}{$sect}{'ACmbNExtraAbisTsMain'};
				my ($ci) = ($bSct{$omc}{$sect}{'CellGlobalIdentity'} =~ /ci\s(\d+)/);
				if ($ci eq '65535') {
					#$excl = 1;
					#print "Found $ci : $rg : $n ..skipping\n";
					next;
				}
				my $hasGprs = (($canGprs eq 'supportedByHW') && ($enGprs eq 'TRUE')) ? 1 : 0;
				my $hasEdge = (($hasTra{$ci} eq 'TRUE') && ($enEgprs eq 'TRUE') ) ? 1 : 0;
				if ($hasEdge == 0) {
					$hasEdge = (($mType{$ci} eq 'M5M') && ($enEgprs eq 'TRUE') ) ? 1 : 0;
				}
				my $cs34 = (($cs > 2) && ($poolTs > 0)) ? 1 : 0;
				if ($cs34 == 0) {
					$cs34 = (($mType{$ci} eq 'M4M') ) ? 1 : 0;
						
				}
				if ($cs34) {
					$rep{$rg}{'Number of CS3/4 Cells'}++;
				}
				if ($hasEdge) {
					$rep{$rg}{'Number of EDGE Cells'}++;
					$edgeBts = 1;
				}
				if ($hasGprs) {
					$rep{$rg}{'Number of GPRS Cells'}++;
					$gprsBts = 1;
				}
				if ($excl == 0) {
					my $fR = $bSct{$omc}{$sect}{'FrequencyRange'};
					if ($fR =~ /undefined/) {
						$fR = ($bSct{$omc}{$sect}{'BCCHFrequency'} < 126) ? 'e_gsm' : 'dcs1800';
					}
					#print "$n\n";
					if ($fR =~ /gsm/i) {
						$has900 = 1;
						$celRep{$rg}{'Total GSM900 Cells'}++;
						$celRep{$rg}{'GSM900 '.uc($dim)}++;
						$celRep{$rg}{'Total GSM900 TRXs'} += $bSct{$omc}{$sect}{'NbBaseBandTransceiver'};
					}
					elsif ($fR =~ /dcs/i) {
						$has1800 = 1;
						$celRep{$rg}{'Total GSM1800 Cells'}++;
						$celRep{$rg}{'Total GSM1800 TRXs'} += $bSct{$omc}{$sect}{'NbBaseBandTransceiver'};
					}
				}
				else {		#exclude = 1 (new,test and mobile sites)
					$excl{$rg}{$bscN}{$n}{'Cells'}++;
					$excl{$rg}{$bscN}{$n}{'TRXs'} += $bSct{$omc}{$sect}{'NbBaseBandTransceiver'};
				}
			}
		}
		#print "$rg;$n;$type;$has900;$has1800\n";
		if ($excl == 0) {
			if ($edgeBts) {
				$celRep{$rg}{'EDGE BTSs'}++;
			}
			elsif ($gprsBts) {
				$celRep{$rg}{'GPRS BTSs'}++;
			}
			if (($has900) && ($has1800)) {
				$rep{$rg}{'BTS(Dual band)'}++ ;
			}
			elsif ($has900){
				$rep{$rg}{'BTS(900)'}++;
				$celRep{$rg}{'BTS(900)'}++;
				$celRep{$rg}{'GSM900 '.$type}++;
			}
			elsif ($has1800) {
				$rep{$rg}{'BTS(1800)'}++;
			}
		}
	}
	
}

my %seenMFS = ();
open(GPU,"output/csv/gpu.csv") or die "Could not open GPU file : $!\n";
while(<GPU>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my $bscN = $line{'BSC'};
		$bscN =~ s/\"//g;
		my $rg = region($bscN);
		my @gpu = split(',',$line{qw/GPUS/});
		$celRep{$rg}{'Total GPU'} = $celRep{$rg}{'Total GPU'} + $#gpu+1;
		$celRep{$rg}{'Total MFS'}++ if not exists($seenMFS{$line{'MFS'}});
		$seenMFS{$line{'MFS'}} = 1;
	}
}
close(GPU);

my %seenMT = ();
my %seenTC = ();
foreach my $omc (keys %circ) {
	foreach my $id (keys %{$circ{$omc}}) {
		my ($bsc,$rack) = ($id =~ /amecID\s(\d+).*?rackRdn\s(\d+)/);
		my $bscN = $bsc{$omc}{$bsc}{'UserLabel'};
		next if not(defined($bscN));
		$bscN =~ s/\"//g;
		my $rg = region($bscN);
		next if ($circ{$omc}{$id}{'AdministrativeState'} eq 'locked' );
		if ($circ{$omc}{$id}{'CircuitPackType'} =~ /(mt120|jbmte3nb|jbmte2)/i ) {
			$rep{$rg}{'TRANSCODERS'}++ if not(exists($seenMT{$omc}{$rack}));
			$seenMT{$omc}{$rack} = 1;
		}
		elsif ($circ{$omc}{$id}{'CircuitPackType'} =~ /asmc/i ) {
			next if ((exists($seenTC{$omc}{$bscN}{'1'})) && ($rack == 2));			#same TC
			$rep{$rg}{'TRANSCODERS'}++ if not(exists($seenTC{$omc}{$bscN}{$rack}));
			$seenTC{$omc}{$bscN}{$rack} = 1;
		}
	}
}

my @reg = qw/CENTRAL EASTERN WESTERN/;
foreach my $r (@reg) {
	$rep{$r}{'Sites'} = $cref->{$r};
}
my @eis = ('TRANSCODERS','Sites','BTS(900)','BTS(1800)','BTS(Dual band)','Number of GPRS Cells','Number of CS3/4 Cells','Number of EDGE Cells');
my @nem = ('BSCs','Total MFS','Total GPU','GPRS BTSs','EDGE BTSs',,'BTS(900)','GSM900 MACRO BTSs','GSM900 MACROCELL','GSM900 MICRO BTSs','GSM900 MICROCELL','Total GSM900 Cells','Total GSM1800 Cells','Total GSM900 TRXs','Total GSM1800 TRXs');

open OUTFILE, ">AlcatelEIS.html" or die "Cannot open AlcatelEIS.html for writing! : $!\n";
print OUTFILE start_html(-title=>"Alcatel Network Element Count Report",-author=>'hartmut.behrens@alcatel.co.za',-age=>'0',-BGCOLOR=>(CLR_BG),-style=>{-code=>"$style"});
print OUTFILE h3("Alcatel Network Element Count Report");
print OUTFILE "Based on OMC export of $date<br>";
print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
print OUTFILE caption("VODACOM ALCATEL EIS REPORT");
print OUTFILE Tr(td(['',@reg]));
foreach my $t (@eis) {
	print OUTFILE "<tr><td>$t</td>\n";
	foreach my $r (@reg) {
		print OUTFILE "<td>".$rep{$r}{$t}."</td>\n";
	}
}
print OUTFILE end_table(),"<BR><BR>\n";
print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
print OUTFILE caption("VODACOM ALCATEL 900/1800 MHz NETWORK COUNT REPORT");
print OUTFILE Tr(td(['',@reg]));
foreach my $t (@nem) {
	print OUTFILE "<tr><td>$t</td>\n";
	foreach my $r (@reg) {
		$celRep{$r}{'GSM900 MICRO BTSs'} = $celRep{$r}{'GSM900 MICROCELL'};		#bugfix for now
		print OUTFILE "<td>".$celRep{$r}{$t}."</td>\n";
	}
	print OUTFILE "</tr>\n";
}
print OUTFILE end_table(),"<BR><BR>\n";
print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
print OUTFILE caption("LIST OF EXCLUDED SITES PER REGION + AFFECTED CELLS and TRXs");
foreach my $r (@reg) {
	print OUTFILE Tr(th($r,'','')),"\n";;
	foreach my $b (keys %{$excl{$r}}) {
		foreach my $n (keys %{$excl{$r}{$b}}) {
			my ($cel,$trx) = @{$excl{$r}{$b}{$n}}{qw/Cells TRXs/};
			print OUTFILE Tr(td([$b,$n,"($cel cells : $trx TRXs)"]));
		}
	}
}
print OUTFILE end_html();
close OUTFILE;
copy('AlcatelEIS.html','/var/www/html/confsheets/AlcatelEIS.html');
copy('AlcatelEIS.html','/var/www/html/confsheets/history/elementCount/AlcatelEIS_'.$date.'.html');
#FTP to ..
if (FTP) {
	$date =~ s/\-//g;
	my $ftp = Net::FTP->new('10.121.23.230', Debug => 0);
	$ftp->login('motusers','motusers');
	$ftp->type('I');
	$ftp->put('AlcatelEIS.html','alcatel_report_'.$date.'.htm');
	$ftp->quit;
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

sub getSites {
	my %count = ();
	my %seen = ();
	my @col = qw/BSCNAME CELL_NAME LAT LON/;
	my $sth = $dbh->prepare("select ".join(',',@col)." from CELLPOSITIONS_GSM");
	$sth->execute();
	while (my @row = $sth->fetchrow_array) {
		my %d = ();
		@d{@col} = @row;
		my $loc = join(',',@d{qw/LAT LON/});
		my $r = substr($d{'BSCNAME'},0,1);
		next unless (($r eq 'C') || ($r eq 'E') || ($r eq 'W'));
		$r = region($d{'BSCNAME'});
		if (($d{'CELL_NAME'} =~ /_mobile$/i) || ($d{'CELL_NAME'} =~ /_new$/i) || ($d{'CELL_NAME'} =~ /_test$/i)) {
			print "Skipping $d{'CELL_NAME'}\n";
			next;
		}
		$count{$r}++ unless exists($seen{$loc});
		$seen{$loc}++;
	}
	return(\%count);
}

sub connectDB {
	my ($dbhref) = @_;
	my ($dbh, $dsn, $drh);
	
	$dsn = 'DBI:mysql:;host=localhost;port=3306';
	$dbh = DBI->connect($dsn, 'tools', 'alcatel');
	$drh = DBI->install_driver('mysql');
	# grab general database information
	my @databases = @{$dbh->selectcol_arrayref("show databases")};	# this is only interesting for debugging purposes
	# does the correct DB exist?
	my $found = 0 ; for (@databases) {$found = 1 if (uc($_) eq uc('alcatelRSA'))};
	return (0) if (!$found);
	$dbh->disconnect;
	# now connect properly
	$dsn = 'DBI:mysql:alcatelRSA;host=localhost;port=3306';
	$$dbhref = DBI->connect($dsn, 'tools', 'alcatel');
	$drh = DBI->install_driver('mysql');
	return (1);
}


__END__
