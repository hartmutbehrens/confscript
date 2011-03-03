#!/usr/bin/perl -w
#!/Perl/bin/Perl.exe -w
#!/usr/local/bin/perl -d:DProf

use warnings;
use strict;

use CGI qw(-no_debug :standard :html3 *table);
use File::Copy;
use Net::FTP;

require "subs.pl";
require "loadACIEsubs.pl";

#load config
my $confFile = "etc/conf.ini";
my ($aref,$href) = read_conf($confFile);
my %config = %{$href};
my ($outpath,$archpath) = @config{qw/OUTPUT_HTML OUTPUT_HISTORY/};


use constant VERSION			=> "1.0";
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
use constant CLR_BG				=> "#77ccff";
use constant CLR_D_BAD_CNT		=> "#ff0000";
use constant CLR_D_QUESTIONS	=> "#ffff00";
use constant CLR_D_STUCK		=> "#ffa500";
use constant CLR_D_PRESENT		=> "#90ee90";
use constant CLR_D_EMPTY		=> "#d3d3d3";
use constant TABLE_WIDTH		=> 900;
use constant CELL_NAME_SIZE		=> 18;


my %ind = ();

my %a925_ind = ();
my %a925_exc = ();
my %q_bsc = ();
my %q_bsc_region = ();
my %n_to_i = ();
my %q_bts = ();
my %q_bts_region = ();

my %q_bts_trx = ();
my %q_bts_trx_region = ();

my %q_card = ();
my %q_card_region = ();

my %tcSummary = ();


my $style = 	"p {font-size: 75%; font-family: sans-serif; text-align: center}\n".
				"h2 {font-family: sans-serif; font: italic; text-align: center}\n".
				"h3 {font-family: sans-serif; font: italic; text-align: center}\n".
				"th {background: ".(CLR_BG_TH)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif}\n".
				"td {background-color: ".(CLR_BG_TD)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif; text-align: center}\n".
				"td.mfs {background-color: ".(CLR_BG_TH)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif; text-align: left}\n".
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


my (undef,undef,undef,$mday,$mon,$year,$wday,undef,undef) = localtime(time);
$year += 1900;
$mon++;


#check if required directories exist - if not,try to create them.
mkdir($archpath) unless (-e $archpath);
mkdir($archpath.'/quantity/') unless (-e $archpath.'/quantity/');
mkdir($archpath.'/config/') unless (-e $archpath.'/config/');
# erase everything in the outpath
unlink <$outpath*.html>;
my %emlBSC = (
	"AlcatelBscInstanceIdentifier"	=>1,
	"UserLabel"			=>1
	);
my %rnlBSC = (
	"BSS_Release" => 1,
	"RnlAlcatelBSCInstanceIdentifier"	=>1,
	"En4DrTrePerTcu" => 1,
	"RnlRelatedMFS" => 1,
	"UserLabel"				=>1,
	"OMC_VERSION" =>1,
	);
my $emlCount = loadACIE("AlcatelBsc","eml",\%emlBSC);
my $rnlCount = loadACIE("RnlAlcatelBSC","rnl",\%rnlBSC);

my %omc = ();
my %region = ();
my @regions = ();
my @omc = keys %rnlBSC;

	
foreach my $omc (@{$aref}) {
	my ($shortRa) = ($config{'OMC'.$omc.'_RA1353RAInstance'} =~ /^A1353RA\_(.*)$/);
	$omc{$config{'OMC'.$omc.'_RA1353RAInstance'}} = $config{"OMC$omc"."_Hostname"};
	$omc{$shortRa} = $config{"OMC$omc"."_Hostname"};
}

print "Generating OUTPUT HTML\n";
#correlation check: get num of BSC's defined in EML,RNL level


# retrieve BTS info
my %site = ();
my @cols;
my %line = ();
print "Retrieving Site Config info\n";
open(SITE,"<".$config{"OUTPUT_CSV"}."site_count.csv") || die "Cannot open ".$config{"OUTPUT_CSV"}."site_count.csv: $!\n";
while (<SITE>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my ($omc,$bsc,$btsId) = @line{qw/OMC BSC_ID BTS_ID/};
		@{$site{$omc}{$bsc}{$btsId}}{qw/BTS_Generation MB4G_Count DB4G_Count DB5E_Count MB5E_Count/} = @line{qw/BTS_Generation MB4G_Count DB4G_Count DB5E_Count MB5E_Count/};
	}
}
close(SITE);
print "END:Retrieving Site Config info\n";
print "Retrieving A925 Config info\n";
my %a925 = ();
my %a925_bsc = ();
open(A925,"<".$config{"OUTPUT_CSV"}."a925.csv") || die "Cannot open a925.csv: $!\n";
while (<A925>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my $vals = join(';',@line{qw/Name Rack Shelf TEI Slot AterMux Ater/});
		push @{$a925_bsc{$line{'BSC'}}}, $vals;
		my ($omc,$rack,$shelf,$tei,$region) = @line{qw/OMC_ID Rack Shelf TEI Region/};
		@{$a925{$region}{$omc}{$rack}{$shelf}{$tei}}{qw/Slot Name AterMux Ater BSC/} = @line{qw/Slot Name AterMux Ater BSC/};
		$tcSummary{$line{'BSC'}}{'RACK'}{$rack}++;
	}
}
close(A925) || die "Cannot close a925.csv: $!\n";
print "END:Retrieving A925 Config info\n";

print "Retrieving BTS info\n";
my %BTS = ();
my %CELL = ();
my %c_to_b = ();
my %poolBSC = ();
open(BTS,"<".$config{"OUTPUT_CSV"}."btsConfig.csv") || die "Cannot open ".$config{"OUTPUT_CSV"}."btsConfig.csv: $!\n";
my @btsColms = qw/SITE_NAME BTS_GENERATION uBTS QMuxAddress PowerLevel MuxRule AdministrativeState OperationalState AbisTopology 2ndAbis SynchBts QmuxTS RANK DXX_FLAG FE_AMP CONTROL FrameUnit Abis_TS_Free 2ndAbis_TS_Free TotalExtraTs/;
my @celColms = qw/CELL_NAME LAC CI SECTOR TRX_NUM TRA_EQUIPPED TRA_AMOUNT TRE_AMOUNT BCCHFrequency SECTOR_RSL_NUM ANX ANX_COUNT ANY ANY_COUNT ANC ANC_COUNT Availability MaxEgprsMcs ExtaAbisTs PoolType2 PoolType3 PoolType4 PoolType5 AGprsMinPdch AGprsMaxPdchHighLoad AGprsMaxPdch Radio_Type/;
@cols = ();
%line = ();
while (<BTS>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		s/\"//g;
		my @data = split(/;/,$_);
		@line{@cols} = @data;
									
		my ($omc,$bsc,$btsId,$sector) = @line{qw/OMC BSC_ID BTS_ID SECTOR/};
		@{$BTS{$omc}{$bsc}{$btsId}}{@btsColms} = @line{@btsColms};
		@{$CELL{$omc}{$bsc}{$btsId}{$sector}}{@celColms} = @line{@celColms};
		$BTS{$omc}{$bsc}{$btsId}{'TRA_EQUIPPED'} = 0 unless exists $BTS{$omc}{$bsc}{$btsId}{'TRA_EQUIPPED'};
		$BTS{$omc}{$bsc}{$btsId}{'TRA_EQUIPPED'}++ if $CELL{$omc}{$bsc}{$btsId}{$sector}{'TRA_EQUIPPED'} eq 'TRUE';
		@{$c_to_b{$line{"LAC"}.';'.$line{"CI"}}}{qw/OMC_ID BSC_ID BTS_ID SECTOR/} = ($omc,$bsc,$btsId,$sector);
		$poolBSC{$omc}{$bsc} += $line{'TotalExtraTs'};
	}
}
close(BTS) || die "Cannot close btsConfig.csv: $!\n";
print "END: Retrieving BTS info\n";
print "Retrieving LapD mapping info\n";
my %lapd = ();

open my $lapd_file,"<",$config{"OUTPUT_CSV"}."lapdConfig.csv" || die "Cannot open rslConfig.csv: $!\n";

while (<$lapd_file>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		$lapd{join(';',@line{qw/LAC CI/})}{$line{'SpeechCodingRate'}}++	if ($line{'LapdLinkUsage'} eq 'rsl');	
	}
}
close $lapd_file;
print "END: Retrieving LapD mapping info\n";
print "Retrieving Pool TS to TCU mapping info\n";
my %pool = ();

open(POOL,"<".$config{"OUTPUT_CSV"}."poolConfig.csv");
while (<POOL>) {
	chomp;
	next if ($. == 1);
	my @data = split(';',$_);
	$pool{$data[0]}{$data[1]}{$data[2]}{$data[3]} = $data[4];
}
close(POOL);

print "END:Retrieving Pool TS to TCU mapping info\n";
print "Retrieving TRX Channel Configuration info\n";
my %trxConfig = ();
my @trxCols = qw(BSC CELLNAME LAC CI TRX CellAllocation CellAllocationDCS HoppingType ChannelConfiguration);
open(TRXCONF,"<".$config{"OUTPUT_CSV"}."trxConfig.csv") || die "Cannot open trxConfig.csv: $!\n";
while (<TRXCONF>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		%{$trxConfig{$line{"BSC"}}{$line{"CI"}}{$line{"TRX"}}} = map { $_ => $line{$_} } @trxCols;
	}
}
close(TRXCONF);
print "END: Retrieving TRX Channel Configuration info\n";
my (%nsei,%gpu);

if (-e $config{"OUTPUT_CSV"}."gpu.csv") {
	
	open(GPU,"<".$config{"OUTPUT_CSV"}."gpu.csv") || die "Cannot open gpu.csv: $!\n";
	while (<GPU>) {
		chomp;
		if ($. == 1) {				#load header line
			@cols = split(/;/,$_);
		}
		else {
			my @data = split(/;/,$_);
			@line{@cols} = @data;
			my ($omc,$mfsName,$bscName) = @line{qw/OMC_ID MFS BSC/};
			$mfsName =~ s/\"//g;
			$bscName =~ s/\"//g;
			$nsei{$bscName} = $line{'NSEIS'};
			@{$gpu{$omc}{$mfsName}{$bscName}}{qw/GPUS NSEIS NSVCS MFS_ID Gb R_SR/} = @line{qw/GPUS NSEIS NSVCS MFS_ID Gb R_SR/};
		}
	}
	close(GPU) || die "Cannot close gpu.csv: $!\n";
}

my %ccpLoad = ();
if (-e $config{"OUTPUT_CSV"}."ccpLoad.csv") {
	open(CCP,"<".$config{"OUTPUT_CSV"}."ccpLoad.csv") || die "Cannot open ccpLoad.csv: $!\n";
	while (<CCP>) {
		chomp;
		if ($. == 1) {				#load header line
			@cols = split(/;/,$_);
		}
		else {
			my @data = split(/;/,$_);
			@line{@cols} = @data;
			my $ccpId = join(',',@line{qw/RACK SHELF SLOT/});
			@{$ccpLoad{$line{'OMC_ID'}}{$line{'BSC_ID'}}{$ccpId}}{@cols} = @data;
		}
	}
	close(CCP) || die "Cannot close ccpLoad.csv: $!\n";
}

my %siteControl = ();
if (-e $config{"OUTPUT_CSV"}."siteControl.csv") {
	open(SITEC,"<".$config{"OUTPUT_CSV"}."siteControl.csv") || die "Cannot open siteControl.csv: $!\n";
	while (<SITEC>) {
		chomp;
		if ($. == 1) {				#load header line
			@cols = split(/;/,$_);
		}
		else {
			my @data = split(/;/,$_);
			@line{@cols} = @data;
			$siteControl{$line{'OMC_ID'}}{$line{'BSC_ID'}}{$line{'BTS_ID'}} = $line{'CONTROL'};
		}
	}
	close(SITEC) || die "Cannot close ccpLoad.csv: $!\n";
}


# retrieve BSC info
print "Retrieving BSC info\n";
my $DATE = "";
my %HIGH_SD = ();
my %BSC = ();
my %bscSum = ();
my %mfsConfig = ();


open(BSC,"<".$config{"OUTPUT_CSV"}."bscConfig.csv") || die "Cannot open bscConfig.csv: $!\n";
while (<BSC>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		s/\"//g;
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my ($omc,$bscName,$bsc,$gen,$date,$config,$mfsName) = @line{qw/OMC_ID NAME BSC_ID GEN IMPORTDATE CONFIG MFS_NAME/};
		next unless defined $bscName || $bscName eq '';
		next if $bscName eq '-';
		print "BSC: $bscName\n";
		my $en4DrTre = defined($rnlBSC{$omc}{$bsc}{'En4DrTrePerTcu'}) && ($rnlBSC{$omc}{$bsc}{'En4DrTrePerTcu'} eq 'TRUE') ? 'Activated' : 'Deactivated';
		@{$mfsConfig{$mfsName}}{qw/MFS_ID MFS_GEN MFSIPADDRESS/} = @line{qw/MFS_ID MFS_GEN MFSIPADDRESS/};
		push @{$mfsConfig{$mfsName}{'BSCs'}}, $bscName;
		my $max_extra_ts = 717;
		unless ($rnlBSC{$omc}{$bsc}{'OMC_VERSION'} =~ /b9/i) {
			$max_extra_ts = 2000 if $gen =~ /evol/i;
		}
		
		
		$n_to_i{$bscName} = $line{'BSC_ID'};
		my $nsei = exists($nsei{$bscName})? $nsei{$bscName} : '-';
		next if ($gen eq 'undefined');
		$line{"BSCX25PRIM"} =~ s/\D//g;
		$DATE = $date;
		
		# add to index file
		#push @{$ind{$omc{$omc}}{$mfsName}}, $bscName;
		$ind{$omc{$omc}}{$mfsName}{$bscName}++;
		# add to quantity file
		$q_bsc{"$gen ($config)"}{$omc{$omc}}++;
		my $region = region($bscName);
		$region{$bscName} = $region;
		$q_bsc_region{"$gen ($config)"}{$region}++;
		#pop all distinct regions into a array for printing purposes
		push @regions,$region unless grep(/$region/,@regions);
		@{$bscSum{$omc{$omc}}{$bscName}}{qw/DATE CONFIG REGION NSEI X25P SPC MSCSPC SMNO N7NO PSNO GSL USAGE LACS RACS BSCIPADDRESS/} = ("$date","$gen ($config)","$region","$nsei",@line{qw/BSCX25PRIM SPC MSC_SPC CS_HWAY_NO N7_NO PS_HWAY_NO GSL_NO Usage LACS RACS BSCIPADDRESS/});
		
		if (1) {
			open OUTFILE, ">$outpath$bscName.html" or die "Cannot open $outpath$bscName.html for writing! : $!\n";
			print OUTFILE start_html(	-title=>"Config Sheet for $bscName",
				-author=>'hartmut.behrens@alcatel.co.za',
				-age=>'0',
				-meta=>{'http-equiv'=>'no-cache',
						'copyright'=>'H Behrens'},
				-BGCOLOR=>(CLR_BG),
				-style=>{-code=>"$style"});
			print OUTFILE h3("Configuration Sheet for $bscName ($date)");
			#shortcuts to various sections of the config sheet
			print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
			print OUTFILE Tr(td({-class=>'blank',-align=>'LEFT'},ul(li([a({-href=>"#Cells"},"Cells"),a({-href=>"#RSL"},"RSL Mapping"),a({-href=>"#Radio"},"Radio Channel Configuration")]))));
			print OUTFILE end_table(),"<BR>\n";
			
			# colour-code
			#print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
			#print OUTFILE caption("Colour Code");
			#print OUTFILE Tr(td({-class=>"etcu"},"Unused TCU"),td({-class=>"mrate"},"Multirate"),td({-class=>"sdhigh"},"SDCCH>32"),td({-class=>"pkt"},"Extra Abis TS"),td({-class=>"hrProb"},"TRE is multiRate, but half rate not enabled") ),"\n";
			#print OUTFILE end_table(),"<BR>\n";
			
			
			print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
			print OUTFILE caption("BSC Set-up"), "\n";;
			print OUTFILE Tr(th(["OMC","BSC Type","Region","BSC IP Address","Prim BSC X25","SPC","DPC","CS HW","N7","NSEI","LACs","RACs","PS HW","GSL","PS HW Usage","Removal of HR Impact"])),"\n";
			print OUTFILE Tr(td([$omc{$omc},"$gen ($config)",$region,@line{qw/BSCIPADDRESS BSCX25PRIM SPC MSC_SPC CS_HWAY_NO N7_NO/},$nsei,@line{qw/LACS RACS PS_HWAY_NO GSL_NO Usage/},$en4DrTre])),"\n";
			print OUTFILE end_table(),"<BR>\n";
			if ($gen ne 'g2') {
				if (exists $ccpLoad{$omc}{$bsc}) {
					print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
					print OUTFILE caption("CCP Load"), "\n";;
					print OUTFILE Tr(th(["CCP Rack/Shelf/Slot","Nb FR RSL","Nb DR RSL","Used RSL (Eq FR)","Free RSL (Eq FR)","%Occupancy"])),"\n";
					foreach my $ccpId (sort keys %{$ccpLoad{$omc}{$bsc}}) {
						my $occy = ($ccpLoad{$omc}{$bsc}{$ccpId}{'EQ_FR'} || 0)/2;
						print OUTFILE Tr(td([$ccpId,@{$ccpLoad{$omc}{$bsc}{$ccpId}}{qw/FR_RSL DR_RSL EQ_FR FREE_RSL/},sprintf("%.1f",$occy).'%'])),"\n";	
					}
					
					print OUTFILE end_table(),"<BR>\n";
				}
			}
			
			print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
			print OUTFILE caption("Extra Abis TS Load"), "\n";;
			print OUTFILE Tr(th(["Extra Abis TS Configured","Max Theoretically Possible","%Occupancy"])),"\n";
			print OUTFILE Tr(td([$poolBSC{$omc}{$bsc},$max_extra_ts,sprintf("%.1f",100*$poolBSC{$omc}{$bsc}/$max_extra_ts)])),"\n";	
			print OUTFILE end_table(),"<BR>\n";
			
			if (defined $a925_bsc{$bscName}) {
				print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
				print OUTFILE caption("A925 Set-up"), "\n";
				print OUTFILE Tr(th(["Transcoder","Rack","Shelf","TEI","Slot","AterMux","Ater"])),"\n";
				foreach my $line (sort @{$a925_bsc{$bscName}}) {
					my @vals = split(';',$line);
					print OUTFILE Tr(td([@vals])),"\n";
				}
				print OUTFILE end_table(),"<BR>\n";
			}
			
			if ($gen eq 'g2') {
				print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
				print OUTFILE caption(a({-name=>"BTSs"},"BTSs")), "\n";
				print OUTFILE Tr(th({-colspan=>4},"Logical"), th({-colspan=>5},"Hardware Config"), th({-colspan=>7},"Transmission")),"\n";
				print OUTFILE Tr(th(["BTS Ix","Synch","Related<br>BTS","Site Name","Cntrl","BTS Type","FE Amp","Q1 TS","Q1 Addr","Abis","Abis Rank","Compression","Free Abis TS","Total Pool TS"])),"\n";
			}
			else {
				print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
				print OUTFILE caption(a({-name=>"BTSs"},"BTSs")), "\n";
				print OUTFILE Tr(th({-colspan=>4},"Logical"), th({-colspan=>6},"Hardware Config"), th({-colspan=>7},"Transmission")),"\n";
				print OUTFILE Tr(th(["BTS Ix","Synch","Related<br>BTS","CCP Mapping","Site Name","Cntrl","BTS Type","FE Amp","Q1 TS","Q1 Addr","Abis","Abis Rank","Compression","Free Abis TS","Total Pool TS"])),"\n";
			}
			
			foreach my $bts (sort {$a <=> $b} keys %{$BTS{$omc}{$bsc}}) {
				#synch BTS info
				my ($sync,$relBts) = ('','');
				if ($BTS{$omc}{$bsc}{$bts}{"SynchBts"} =~ /master.*?moiRdn/i) {
						my ($masterBts) = ($BTS{$omc}{$bsc}{$bts}{"SynchBts"} =~ /moiRdn\s(\d+)/);
						$sync = "SLAVE";
						$relBts = "BTS $masterBts";
				}
				elsif ($BTS{$omc}{$bsc}{$bts}{"SynchBts"} =~ /slave.*?moiRdn/i) {
					my ($slaveBts) = ($BTS{$omc}{$bsc}{$bts}{"SynchBts"} =~ /moiRdn\s(\d+)/);
					$sync = "MASTER";
					$relBts = "BTS $slaveBts";
				}
				#microbts info
				$BTS{$omc}{$bsc}{$bts}{"BTS_GEN"} = $BTS{$omc}{$bsc}{$bts}{"BTS_GENERATION"};
				if ($BTS{$omc}{$bsc}{$bts}{"BTS_GENERATION"} eq 'evolium:micro') {
					my ($mb4,$db4,$db5,$mb5) = @{$site{$omc}{$bsc}{$bts}}{qw/MB4G_Count DB4G_Count DB5E_Count MB5E_Count/};
					$BTS{$omc}{$bsc}{$bts}{"BTS_GEN"} = (($mb4+$db4 > 0)? ($mb4+$db4).' M4M ':'').(($mb5+$db5 > 0)? ($mb5+$db5).' M5M ':'');
				}
				#abis counts
				#$BTS{$omc}{$bsc}{$bts}{"Abis_Free"} = $BTS{$omc}{$bsc}{$bts}{"Abis_TS_Free"}.(($BTS{$omc}{$bsc}{$bts}{"2ndAbis_TS_Free"} =~ /\d+/)?','.$BTS{$omc}{$bsc}{$bts}{"2ndAbis_TS_Free"}:'');
				$BTS{$omc}{$bsc}{$bts}{"Abis_Free"} = 'Eish!';
				
				if ($gen eq 'g2') {
					print OUTFILE Tr(td([$bts,$sync,$relBts,@{$BTS{$omc}{$bsc}{$bts}}{qw/SITE_NAME CONTROL BTS_GEN FE_AMP QmuxTS QMuxAddress AbisTopology RANK DXX_FLAG Abis_Free TotalExtraTs/}])),"\n";
				}
				else {
					print OUTFILE Tr(td([$bts,$sync,$relBts,$siteControl{$omc}{$bsc}{$bts},@{$BTS{$omc}{$bsc}{$bts}}{qw/SITE_NAME CONTROL BTS_GEN FE_AMP QmuxTS QMuxAddress AbisTopology RANK DXX_FLAG Abis_Free TotalExtraTs/}])),"\n";
				}
				#quantities
				my ($OMC,$reg) = ($omc{$omc},$region);
				($OMC,$reg) = ('Test','Test') if ($BTS{$omc}{$bsc}{$bts}{"SITE_NAME"} =~ /_test/i);
				($OMC,$reg) = ('New','New') if ($BTS{$omc}{$bsc}{$bts}{"SITE_NAME"} =~ /_new/i);
				$q_bts{$BTS{$omc}{$bsc}{$bts}{"BTS_GENERATION"}}{$OMC}++;
				
				$q_bts_trx{$BTS{$omc}{$bsc}{$bts}{"BTS_GENERATION"}}{$OMC}{"site"}++;
				$q_bts_trx_region{$BTS{$omc}{$bsc}{$bts}{"BTS_GENERATION"}}{$reg}{"site"}++;
			}
			print OUTFILE end_table(),"<BR>\n";
	
			print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
			print OUTFILE caption(a({-name=>"Cells"},"Cells")), "\n";
			print OUTFILE Tr(th({-colspan=>6},"Logical"), th({-colspan=>3},"Hardware Config"),th({-colspan=>1},"MultiRate Config")),"\n";
			print OUTFILE Tr(th(["BTS Ix","Cell Name","LAC","CI","BCCH","MIN / HIGHGLOAD / MAX<br>PDCH","TRX Count","RSL Count","Radio Type","Fullrate/Dualrate TRXs"])),"\n";
			
			foreach my $bts (sort {$a <=> $b} keys %{$CELL{$omc}{$bsc}}) {
				my ($gen,$sitename) = @{$BTS{$omc}{$bsc}{$bts}}{qw/BTS_GENERATION SITE_NAME/};
				foreach my $sector (sort {$a <=> $b} keys %{$CELL{$omc}{$bsc}{$bts}}) {
					my ($lac,$ci) = @{$CELL{$omc}{$bsc}{$bts}{$sector}}{qw/LAC CI/};
					my $fr_trx = exists $lapd{$lac.';'.$ci}{'fullRate'} ? $lapd{$lac.';'.$ci}{'fullRate'}.'FR' : '';
					my $dr_trx = exists $lapd{$lac.';'.$ci}{'multiRate'} ? $lapd{$lac.';'.$ci}{'multiRate'}.'DR' : '';
					$CELL{$omc}{$bsc}{$bts}{$sector}{'ExtaAbisTs'} = 'B9' if ($rnlBSC{$omc}{$bsc}{'BSS_Release'} eq 'b9');
					#AGprsMinPdch AGprsMaxPdchHighLoad AGprsMaxPdch
					$CELL{$omc}{$bsc}{$bts}{$sector}{'PdchConfig'} = join('/',@{$CELL{$omc}{$bsc}{$bts}{$sector}}{qw/AGprsMinPdch AGprsMaxPdchHighLoad AGprsMaxPdch/});
					print OUTFILE Tr(td([$bts,@{$CELL{$omc}{$bsc}{$bts}{$sector}}{qw/CELL_NAME LAC CI BCCHFrequency PdchConfig TRX_NUM SECTOR_RSL_NUM Radio_Type/},join(' ',$fr_trx,$dr_trx)])),"\n";
					my ($OMC,$reg) = ($omc{$omc},$region);				
					($OMC,$reg) = ('Test','Test') if ($sitename =~ /_test/i);
					($OMC,$reg) = ('New','New') if ($sitename =~ /_new/i);

					#add num of TRX to quantity
					$q_bts_trx{$gen}{$OMC}{"trx"} += $CELL{$omc}{$bsc}{$bts}{$sector}{'SECTOR_RSL_NUM'};
					$q_bts_trx{$gen}{$OMC}{"cells"}++;
					$q_bts_trx_region{$gen}{$reg}{"trx"} += $CELL{$omc}{$bsc}{$bts}{$sector}{'SECTOR_RSL_NUM'};
					$q_bts_trx_region{$gen}{$reg}{"cells"}++;
					$q_bts_region{$BTS{$omc}{$bsc}{$bts}{"BTS_GENERATION"}}{$reg}++;				
				}
			}
			print OUTFILE end_table(),"<BR>\n";
			
			
			my @TS = qw(TS1 TS2 TS3 TS4 TS5 TS6 TS7 TS8);
			my @cfg = ("Type","MAIO","HG");
			print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
			print OUTFILE caption(a({-name=>"Radio"},"Radio Channel Configuration")), "\n";
			print OUTFILE Tr(th({-colspan=>6},["Cell Information"]),th({-colspan=>3},["TS1","TS2","TS3","TS4","TS5","TS6","TS7","TS8"])),"\n";
			print OUTFILE Tr(th(["Cell Name","LAC","CI","TRX","Cell Allocation","HoppingType",(@cfg) x 8])),"\n";
			foreach my $ci (sort keys %{$trxConfig{$bscName}}) {
				foreach my $trx (sort keys %{$trxConfig{$bscName}{$ci}}) {
					my %radioChannel = ();
					my (undef,$cellName,$lac,$ci,undef,$ca,$caDCS,$hopType,$channel) = @{$trxConfig{$bscName}{$ci}{$trx}}{@trxCols};
					@{$radioChannel{'CHANNEL'}}{@TS} = ($channel =~ /channelCombination\s(\w+)/g);
					@{$radioChannel{'MAIO'}}{@TS} = ($channel =~ /maio\s(\d+)/g);
					@{$radioChannel{'HG'}}{@TS} = ($channel =~ /hoppingGroup\s(\d+)/g);
					print OUTFILE "<tr>",td($cellName),td($lac),td(a({-name=>"$ci"},$ci)),td($trx),td(($ca =~ /\d+/)?$ca:$caDCS),td($hopType);
					foreach (@TS) {
						print OUTFILE td($radioChannel{'CHANNEL'}{$_}),td(defined($radioChannel{'MAIO'}{$_})?$radioChannel{'MAIO'}{$_}:'-' ),td(defined($radioChannel{'HG'}{$_})?$radioChannel{'HG'}{$_}:'-'),"\n";
					}
					print OUTFILE "</tr>\n";
				}
			}
			print OUTFILE end_table(),"<BR>\n";
			print OUTFILE end_html();
			close OUTFILE;
		}
	}
}
close(BSC) || die "Cannot close bscConfig.csv: $!\n";
print "END: Retrieving BSC info\n";


print "Creating HIGH SDCCH load report\n";
my $sdTotal = 0;
#do SDCCH >= 32 on one TCU check
open(SDFILE,">$outpath"."SDCCH_TCU_LOAD.html") || die "Cannot open file $outpath"."SDCCH_TCU_LOAD.html. Error is $!\n";
print SDFILE start_html(	-title=>"HIGH SDCCH LOAD ON TCU CHECK",
				-author=>'hartmut.behrens@alcatel.co.za',
				-age=>'0',
				-meta=>{'http-equiv'=>'no-cache',
						'copyright'=>'H Behrens'},
				-BGCOLOR=>(CLR_BG),
				-style=>{-code=>"$style"});
print SDFILE h3("HIGH SDCCH LOAD ON TCU");
print SDFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print SDFILE caption("Details"), "\n";
print SDFILE Tr(th(["OMC","BSC","TCU","Number Of SDCCH"])),"\n";
foreach my $sd_count (sort {$b <=> $a}keys %HIGH_SD) {
	foreach my $omc (keys %{$HIGH_SD{$sd_count}}) {
		foreach my $bsc (sort keys %{$HIGH_SD{$sd_count}{$omc}}) {
			my $bscName = $rnlBSC{$omc}{$bsc}{"UserLabel"};
			$bscName =~ s/\"//g;
			foreach my $tcu (sort keys %{$HIGH_SD{$sd_count}{$omc}{$bsc}}) {
				print SDFILE Tr(td([$omc,a({href=>"$bscName.html"},$bscName),$tcu,$sd_count])),"\n";
				$sdTotal++;
			}
		}
	}
}

	

print SDFILE end_table(),"<BR>\n";
print SDFILE end_html();
close(SDFILE);
print "END: Creating HIGH SDCCH load report\n";

#create abis-alarm report
print "Creating Abis Alarm Report\n";
open(ABFILE,">$outpath"."ABIS_ALARM_DISABLED.html") || die "Cannot open file $outpath"."ABIS_ALARM_DISABLED.html. Error is $!\n";
print ABFILE start_html(	-title=>"A-bis Links for which Alarm Reporting is Disabled",
				-author=>'hartmut.behrens@alcatel.co.za',
				-age=>'0',
				-meta=>{'http-equiv'=>'no-cache',
						'copyright'=>'H Behrens'},
				-BGCOLOR=>(CLR_BG),
				-style=>{-code=>"$style"});
print ABFILE h3("A-bis Links for which Alarm Reporting is Disabled");
my %abRep = ();
my %ab_noBTS = ();
my ($a1,$a2,$a3,$a4) = (0,0,0,0);
open(ABREP,"<".$config{"OUTPUT_CSV"}."abisReport.csv");
while (<ABREP>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my $omc = $line{"OMC_ID"};
		my $bsc = $line{"BSC_ID"};
		my $bts = $line{"BTS_ID"};
		my $site = $line{"SITE_NAME"};
		my $tp = $line{"BSC_ABIS_TP_NUMBER"};
		my $bscTp = $line{"BSC_TP_STATE"};
		my $site1 = $line{"SITE_TP_1_STATE"};
		my $site2 = $line{"SITE_TP_2_STATE"};
		my $type = $line{"ABIS_TYPE"};
		$abRep{$omc}{$bsc}{$bts}{$tp}{"SITE"} = $site;
		$abRep{$omc}{$bsc}{$bts}{$tp}{"BSC_TP_STATE"} = $bscTp;
		$abRep{$omc}{$bsc}{$bts}{$tp}{"SITE_1"} = $site1;
		$abRep{$omc}{$bsc}{$bts}{$tp}{"SITE_2"} = $site2;
		$abRep{$omc}{$bsc}{$bts}{$tp}{"Type"} = $type;
	}
}
close(ABREP);

open(ABNOBTS,"<".$config{"OUTPUT_CSV"}."abis_noBTS.csv");
while (<ABNOBTS>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my $omc = $line{"OMC_ID"};
		my $bsc = $line{"BSC_NAME"};
		my $tp = $line{"BSC_ABIS_TP_NUMBER"};
		my $bscTpState = $line{"BSC_TP_STATE"};
		my $type = $line{"ABIS_TYPE"};
		$ab_noBTS{$omc}{$bsc}{$tp}{"BSC_TP_STATE"} = $bscTpState;
		$ab_noBTS{$omc}{$bsc}{$tp}{"ABIS_TYPE"} = $type;
	}
}
close(ABNOBTS);
# first - all ring configs...
my $info = '(Admin/Operational/Availability)';
print ABFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print ABFILE caption("Ring configurations with any one TP locked"), "\n";
print ABFILE Tr(th(["OMC","BSC","Site Name","BSC Abis TP Number","BSC TP State","Site TP 1<br>$info","Site TP 2<br>$info","A-bis Type"])),"\n";
foreach my $omc (sort keys %abRep) {
	foreach my $bsc (keys %{$abRep{$omc}}) {
		my $bscId = "{ amecID ".$bsc.", moiRdn 1}";
		my $bscName = $emlBSC{$omc}{$bscId}{"UserLabel"};
		$bscName =~ s/\"//g;
		foreach my $bts (keys %{$abRep{$omc}{$bsc}}) {
			foreach my $tp (keys %{$abRep{$omc}{$bsc}{$bts}}){
				
				my ($type,$site,$bscTp,$site1,$site2) = @{$abRep{$omc}{$bsc}{$bts}{$tp}}{qw/Type SITE BSC_TP_STATE SITE_1 SITE_2/};
				next if not($type =~ /ring/ );
				
				if ($bscTp =~ /^locked/) {
					print ABFILE Tr(td([$omc,$bscName,$site,$tp,$bscTp,$site1,$site2,$type])),"\n";
					$a1++;
					next;
				}
				elsif ($site1 =~ /^locked/) {
					print ABFILE Tr(td([$omc,$bscName,$site,$tp,$bscTp,$site1,$site2,$type])),"\n";
					$a1++;
					next;
				}
				elsif ($site2 =~ /^locked/) {
					print ABFILE Tr(td([$omc,$bscName,$site,$tp,$bscTp,$site1,$site2,$type])),"\n";
					$a1++;
					next;
				}
				else {
					next;
				}
				
			}
		}
	}
}
print ABFILE end_table(),"<BR>\n";
# all chains where the bsc or the first tp is locked
print ABFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print ABFILE caption("Chain configurations with BSC or TP1 locked"), "\n";
print ABFILE Tr(th(["OMC","BSC","Site Name","BSC Abis TP Number","BSC TP State","Site TP 1<br>$info","Site TP 2<br>$info","A-bis Type"])),"\n";
foreach my $omc (sort keys %abRep) {
	foreach my $bsc (keys %{$abRep{$omc}}) {
		my $bscId = "{ amecID ".$bsc.", moiRdn 1}";
		my $bscName = $emlBSC{$omc}{$bscId}{"UserLabel"};
		$bscName =~ s/\"//g;
		foreach my $bts (keys %{$abRep{$omc}{$bsc}}) {
			foreach my $tp (keys %{$abRep{$omc}{$bsc}{$bts}}){
				my ($type,$site,$bscTp,$site1,$site2) = @{$abRep{$omc}{$bsc}{$bts}{$tp}}{qw/Type SITE BSC_TP_STATE SITE_1 SITE_2/};
				next if not($type =~ /chain/ );
				
				if ($bscTp =~ /^locked/) {
					print ABFILE Tr(td([$omc,$bscName,$site,$tp,$bscTp,$site1,$site2,$type])),"\n";
					$a2++;
					next;
				}
				elsif ($site1 =~ /^locked/) {
					print ABFILE Tr(td([$omc,$bscName,$site,$tp,$bscTp,$site1,$site2,$type])),"\n";
					$a2++;
					next;
				}
				else {
					next;
				}
			}
		}
	}
}
print ABFILE end_table(),"<BR>\n";

print ABFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print ABFILE caption("Chain configurations with rank other than highest with only TP2 locked"), "\n";
print ABFILE Tr(th(["OMC","BSC","Site Name","BSC Abis TP Number","BSC TP State","Site TP 1<br>$info","Site TP 2<br>$info","A-bis Type"])),"\n";
foreach my $omc (sort keys %abRep) {
	foreach my $bsc (keys %{$abRep{$omc}}) {
		my $bscId = "{ amecID ".$bsc.", moiRdn 1}";
		my $bscName = $emlBSC{$omc}{$bscId}{"UserLabel"};
		$bscName =~ s/\"//g;
		foreach my $bts (keys %{$abRep{$omc}{$bsc}}) {
			foreach my $tp (keys %{$abRep{$omc}{$bsc}{$bts}}){
				my ($type,$site,$bscTp,$site1,$site2) = @{$abRep{$omc}{$bsc}{$bts}{$tp}}{qw/Type SITE BSC_TP_STATE SITE_1 SITE_2/};
				next if not($type =~ /chain/ );
				if (($bscTp =~ /unlocked/) && ($site1 =~ /^locked/) && ($site2 =~ /unlocked/)) {
					print ABFILE Tr(td([$omc,$bscName,$site,$tp,$bscTp,$site1,$site2,$type])),"\n";
					$a3++;
					next;
				}
				else {
					next;
				}
				
			}
		}
	}
}
print ABFILE end_table(),"<BR>\n";

print ABFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print ABFILE caption("BSC Abis-TP\'s that are created but no BTS is connected"), "\n";
print ABFILE Tr(th(["OMC","BSC","BSC Abis TP Number","BSC TP State","A-bis Type"])),"\n";
foreach my $omc (sort keys %ab_noBTS) {
	foreach my $bsc (sort keys %{$ab_noBTS{$omc}}) {
		foreach my $tp (sort {$a <=> $b} keys %{$ab_noBTS{$omc}{$bsc}}) {
			my $state = $ab_noBTS{$omc}{$bsc}{$tp}{"BSC_TP_STATE"};
			my $type = $ab_noBTS{$omc}{$bsc}{$tp}{"ABIS_TYPE"};
			my $bscName = $bsc;
			$bscName =~ s/\"//g;
			print ABFILE Tr(td([$omc,$bscName,$tp,$state,$type])),"\n";
			$a4++;
		}
	}
}
print ABFILE end_html();
close(ABFILE);
print "Adding 2nd Abis Alarm report\n";
open(ABFILE,">$outpath"."ABIS2.html") || die "Cannot open file $outpath"."ABIS2.html. Error is $!\n";
print ABFILE start_html(	-title=>"2nd Abis Alarm Report",
				-author=>'hartmut.behrens@alcatel.co.za',
				-age=>'0',
				-meta=>{'http-equiv'=>'no-cache',
						'copyright'=>'H Behrens'},
				-BGCOLOR=>(CLR_BG),
				-style=>{-code=>"$style"});
print ABFILE h3("2nd A-bis Alarm Report");
print ABFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print ABFILE caption("Sites with 2nd Abis installed"), "\n";
print ABFILE Tr(th(["BSC","Site Name","2nd Abis BSC TP","BSC TP State"])),"\n";
my %ab2 = ();
open(AB2,"<".$config{"OUTPUT_CSV"}."abisReport2.csv");
while (<AB2>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		$ab2{$line{'BSC_NAME'}}{$line{'BSC_2NDABIS_TP_NUMBER'}}{'SITE'} = $line{'SITE_NAME'};
		$ab2{$line{'BSC_NAME'}}{$line{'BSC_2NDABIS_TP_NUMBER'}}{'STATE'} = $line{'BSC_TP_STATE'};
	}
}
close(AB2);
foreach my $bsc (sort keys %ab2) {
	foreach my $tp (sort keys %{$ab2{$bsc}}) {
		my $state = $ab2{$bsc}{$tp}{'STATE'};
		my $dispClass = $state eq 'locked' ? 'mtrx' : '';
		print ABFILE Tr(td([$bsc,$ab2{$bsc}{$tp}{'SITE'},$tp]),td({-class=>$dispClass},$state)),"\n";
		
	}
}
print ABFILE end_table(),"<BR>\n";
print "END:Creating Abis Alarm Report\n";
#Generate A925 TC OUTPUT

print "Creating A925 TC HTML output\n";
foreach my $reg (keys %a925) {
	foreach my $omc (keys %{$a925{$reg}}) {
		foreach my $rack (keys %{$a925{$reg}{$omc}}) {
			# add to index file
			push @{$a925_ind{$omc{$omc}}}, uc($reg)."_A925_$omc{$omc}"."_Rack$rack";
			open(FILE,">$outpath".uc($reg)."_A925_$omc{$omc}"."_Rack$rack".".html") || die "Cannot open file $outpath".uc($reg)."A925_$omc{$omc}"."_Rack$rack".".html. Error is $!\n";
			print FILE start_html(	-title=>"Configuration Sheet for A925 TC Rack $rack ($omc{$omc}), $reg region",
						-author=>'hartmut.behrens@alcatel.co.za',
						-age=>'0',
						-meta=>{'http-equiv'=>'no-cache',
								'copyright'=>'H Behrens'},
						-BGCOLOR=>(CLR_BG),
						-style=>{-code=>"$style"});
			print FILE h3("Configuration Sheet for A925 TC Rack $rack ($omc{$omc}) ($DATE) ".uc($reg)." Region");
			print FILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
			print FILE caption("A925 Set-up"), "\n";
			print FILE Tr(th(["Transcoder","BSC" ,"Shelf","TEI","Slot","AterMux","Ater"])),"\n";
			foreach my $shelf (sort keys %{$a925{$reg}{$omc}{$rack}}) {
				foreach my $tei (sort keys %{$a925{$reg}{$omc}{$rack}{$shelf}}) {
					my ($bscName,$name,$atermux,$ater,$slot) = @{$a925{$reg}{$omc}{$rack}{$shelf}{$tei}}{qw/BSC Name AterMux Ater Slot/};
					$bscName =~ s/\"//g;
					print FILE Tr(td([$name,$bscName,$shelf,$tei,$slot,$atermux,$ater])),"\n";
				}
			}
			print FILE end_table(),"<BR>\n";
			print FILE end_html();
			close FILE;
		}
	}
}
print "END: Creating A925 TC HTML output\n";
#generate TC summary output
print "Creating TC SUMMARY HTML output\n";
open(TCHTML,">$outpath"."tcSummary.html") || die "Cannot open file $outpath"."tcSummary.html. Error is $!\n";
print TCHTML start_html(	-title=>"TC Summary Report",
				-author=>'hartmut.behrens@alcatel.co.za',
				-age=>'0',
				-meta=>{'http-equiv'=>'no-cache',
					'copyright'=>'H Behrens'},
				-BGCOLOR=>(CLR_BG),
				-style=>{-code=>"$style"});
print TCHTML h3("Transcoder Configuration Summary Sheet");

my %tcSum = ();
open(TCSUM,"<".$config{"OUTPUT_CSV"}."tcSummary.csv") || die "Cannot open tcSummary.csv: $!\n";
while (<TCSUM>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		%{$tcSum{$line{"OMC_ID"}}{$line{"REGION"}}{$line{"BSC"}}} = map { $_ => $line{$_} } @cols;
		$tcSummary{$line{'BSC'}}{'ASMC'} += $line{'ASMC'};
		$tcSummary{$line{'BSC'}}{'ATBX'} += $line{'ATBX'};
		$tcSummary{$line{'BSC'}}{'DT16'} += $line{'DT16'};
		$tcSummary{$line{'BSC'}}{'MT120'} += $line{'MT120'};
	}
}
close(TCSUM) || die "Cannot close tcSummary.csv: $!\n";
#read a-channel problems
open(ASUM,"<".$config{"OUTPUT_CSV"}."aChsum.csv") || die "Cannot open aChsum.csv: $!\n";
my %asumBsc =();
while (<ASUM>) {
	chomp;
	my @data = split(/;/,$_);
	$asumBsc{$data[0]} = $data[1];
}
close(ASUM);
foreach my $omc (sort keys %tcSum) {
	foreach my $region (sort keys %{$tcSum{$omc}}) {
		my %totals = ();
		print TCHTML start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
		print TCHTML caption("$omc{$omc} : \u$region Region Transcoder Summary. Click on a BSC link for A-channel report."), "\n";
		print TCHTML Tr(th(["BSC","SM Highway","MT120","ASMC","ATBX","DT16","Unavailable A-CH"])),"\n";
		foreach my $bsc (sort bscsort keys %{$tcSum{$omc}{$region}}) {
			my $achBSCLink = a({href=>"achannel/achproblem_".$bsc."_".$DATE.".html"},$bsc);
			$totals{"SMHW"} += $tcSum{$omc}{$region}{$bsc}{"SMHW"};
			$totals{"MT120"} += $tcSum{$omc}{$region}{$bsc}{"MT120"};
			$totals{"ASMC"} += $tcSum{$omc}{$region}{$bsc}{"ASMC"};
			$totals{"ATBX"} += $tcSum{$omc}{$region}{$bsc}{"ATBX"};
			$totals{"DT16"} += $tcSum{$omc}{$region}{$bsc}{"DT16"};
			$totals{"ACHPROB"} += $asumBsc{$bsc};
			print TCHTML Tr(td([$achBSCLink,$tcSum{$omc}{$region}{$bsc}{"SMHW"},$tcSum{$omc}{$region}{$bsc}{"MT120"},
			$tcSum{$omc}{$region}{$bsc}{"ASMC"},$tcSum{$omc}{$region}{$bsc}{"ATBX"},$tcSum{$omc}{$region}{$bsc}{"DT16"},$asumBsc{$bsc}])),"\n";
		}
		print TCHTML Tr(th(["TOTAL",$totals{"SMHW"},$totals{"MT120"},$totals{"ASMC"},$totals{"ATBX"},$totals{"DT16"},$totals{"ACHPROB"}])),"\n";
		print TCHTML end_table(),"<BR>\n";
	}
}
print TCHTML end_html();
print "END: Creating TC SUMMARY HTML output\n";


open BSCSUM, ">$outpath"."bscConfig.html" or die "Cannot open $outpath"."bscConfig.html for writing! : $!\n";
print BSCSUM start_html(	-title=>"BSC Setup Summary",
		-author=>'hartmut.behrens@alcatel.co.za',
		-age=>'0',
		-meta=>{'http-equiv'=>'no-cache',
				'copyright'=>'H Behrens'},
		-BGCOLOR=>(CLR_BG),
		-style=>{-code=>"$style"});
print BSCSUM h3("BSC Setup Summary");
print BSCSUM start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print BSCSUM caption("BSC Set-up"), "\n";;
print BSCSUM Tr(th(["BSC ID","BSC Name","OMC","BSC Type","Region","BSC IP ADDRESS","Prim BSC X25","SPC","DPC","CS HW","N7","NSEI","LACs","RACs","PS HW","GSL","Usage","Transcoders"])),"\n";
foreach my $omc (reverse sort keys %bscSum) {
	foreach my $bsc (sort keys %{$bscSum{$omc}}) {
		my @tc = ();
		
		if (defined($tcSummary{$bsc}{'MT120'}) && ($tcSummary{$bsc}{'MT120'} > 0)) {
			my @racks = keys %{$tcSummary{$bsc}{'RACK'}};
			my @links = map(a({href=>uc($bscSum{$omc}{$bsc}{'REGION'})."_A925_$omc"."_Rack$_".".html"},'Rack_'.$_),@racks);
			push(@tc,$tcSummary{$bsc}{'MT120'}.'MT120 ('.join(',',@links).')');
		}
		for (qw/ASMC ATBX DT16/) {
			push(@tc,$tcSummary{$bsc}{$_}.$_) if (defined($tcSummary{$bsc}{$_}) && ($tcSummary{$bsc}{$_} > 0));
		}
		$bscSum{$omc}{$bsc}{'TC'} = join(' <nobr>',@tc);
		print BSCSUM Tr(td([$n_to_i{$bsc},$bsc,$omc,@{$bscSum{$omc}{$bsc}}{qw/CONFIG REGION BSCIPADDRESS X25P SPC MSCSPC SMNO N7NO NSEI LACS RACS PSNO GSL USAGE TC/}])),"\n";
	}
}
print BSCSUM end_table();
close(BSCSUM) || die "Cannot close bscConfig.html: $!\n";

open my $mfs_file,'>', $outpath.'mfs_config.html' || die "Cannot open mfs_config.html in $outpath for writing! Error is $!\n";
print $mfs_file start_html(	-title=>"MFS Setup Summary",
		-author=>'hartmut.behrens@alcatel-lucent.co.za',
		-age=>'0',
		-meta=>{'http-equiv'=>'no-cache',
				'copyright'=>'H Behrens'},
		-BGCOLOR=>(CLR_BG),
		-style=>{-code=>"$style"});
print $mfs_file h3("MFS Setup Summary");
print $mfs_file start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print $mfs_file caption("MFS Set-up"), "\n";;
print $mfs_file Tr(th(["MFS ID","MFS Name","MFS IP Address","MFS Type","Associated BSCs"])),"\n";
foreach my $mfs_name (sort {$mfsConfig{$a}{'MFS_ID'} <=> $mfsConfig{$b}{'MFS_ID'}} keys %mfsConfig) {
	my ($id,$gen,$ip) = @{$mfsConfig{$mfs_name}}{qw/MFS_ID MFS_GEN MFSIPADDRESS/};
	my $bsc = join(', ',@{$mfsConfig{$mfs_name}{'BSCs'}});
	print $mfs_file Tr(td([$id,$mfs_name,$ip,$gen,$bsc])),"\n";
}
print $mfs_file end_table();
close $mfs_file;



print "Creating MFS HTML output\n";
foreach my $omc (keys %gpu) {
	foreach my $mfsName (keys %{$gpu{$omc}}) {
		# add to index file
		open(FILE,">$outpath"."$mfsName.html") || die "Cannot open file $outpath $mfsName.html. Error is $!\n";
		print FILE start_html(	-title=>"Configuration Sheet for $mfsName",
					-author=>'hartmut.behrens@alcatel.co.za',
					-age=>'0',
					-meta=>{'http-equiv'=>'no-cache',
							'copyright'=>'H Behrens'},
					-BGCOLOR=>(CLR_BG),
					-style=>{-code=>"$style"});
		print FILE h3("Configuration Sheet for $mfsName ($DATE)");
		print FILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
		print FILE caption("MFS Set-up"), "\n";
		print FILE Tr(th(["MFS NAME","MFS ID","MFS GENERATION","NETWORK ADDRESS"])),"\n";
		print FILE Tr(td([$mfsName,@{$mfsConfig{$mfsName}}{qw/MFS_ID MFS_GEN MFSIPADDRESS/}])),"\n";	
		print FILE end_table;
			
		print FILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
		print FILE caption("BSC's connected to MFS"), "\n";
		print FILE Tr(th(["BSC NAME","GPU's","NSEI's","NSVC's per NSEI","Gb Bandwidth","GPU Rack/Subrack"])),"\n";
		foreach my $bscName (sort keys %{$gpu{$omc}{$mfsName}}) {
			print FILE Tr(td([$bscName,@{$gpu{$omc}{$mfsName}{$bscName}}{qw/GPUS NSEIS NSVCS Gb R_SR/}])),"\n";	
		}
		print FILE end_table;
		close FILE;
	}
}
print "END: Creating MFS HTML output\n";


#generate Equipment Quantity count
print "Generating Regional Equipment Quantities\n";
open RFILE, ">$outpath"."q_regional.html" or die "Cannot open $outpath"."q_regional.html for writing! : $!\n";
print RFILE start_html(	-title=>"Network-wide Equipment Quantities, per Region",
			-author=>'rivanov@alcatel.co.za',
			-age=>'0',
			-meta=>{'http-equiv'=>'no-cache',
					'copyright'=>'H Behrens'},
			-BGCOLOR=>(CLR_BG),
			-style=>{-code=>"$style"} );
print RFILE h3("Network-wide Equipment Quantities, per Region, generated ".scalar(localtime));
print RFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print RFILE caption("BSC Level"), "\n";
print RFILE Tr(th(["Region", @regions, "Network"])),"\n";
my %total = ();
for my $bsctype (sort keys %q_bsc_region) {
	my $q_for_this_type = 0;
	my $q_for_region = 0;
	print RFILE "<TR>";
	print RFILE th($bsctype);
	foreach my $region (@regions) {
		if (exists ($q_bsc_region{$bsctype}{$region})) {
			print RFILE td($q_bsc_region{$bsctype}{$region});
			$total{$region} += $q_bsc_region{$bsctype}{$region};
			$q_for_this_type += $q_bsc_region{$bsctype}{$region};
		}
		else {
			print RFILE td("");
		}
	}
	print RFILE td($q_for_this_type);
	$total{'Network'} += $q_for_this_type;
	print RFILE "</TR>\n";
}
print RFILE Tr(th(["Total",@total{@regions},$total{'Network'}]));
print RFILE end_table(),"<BR>\n";

push(@regions,'Test');
push(@regions,'New');

print RFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print RFILE caption("BTS Level"), "\n";
print RFILE "<TR>";
print RFILE th("Type");

print RFILE th({-colspan=>3},[@regions]);

print RFILE th({-colspan=>3},"Network Total");
print RFILE "</TR>\n";

print RFILE "<TR>";
print RFILE th("");
foreach (@regions) {
	print RFILE th(["Sites","Cells","TRX"]);
}
print RFILE th(["Sites","Cells","TRX"]);
print RFILE "</TR>\n";
my %tot_reg = ();
my %total_reg = ();
for my $btstype (sort keys %q_bts_region) {
	my $q_for_this_type = 0;
	my $q_site = 0;
	my $q_trx = 0;
	
	print RFILE "<TR>";
	print RFILE th($btstype);
	foreach my $region (@regions) {
		if (exists ($q_bts_region{$btstype}{$region})) {
			print RFILE td([$q_bts_trx_region{$btstype}{$region}{"site"},$q_bts_region{$btstype}{$region},$q_bts_trx_region{$btstype}{$region}{"trx"}]);
			$q_site += $q_bts_trx_region{$btstype}{$region}{"site"};
			$q_for_this_type += $q_bts_trx_region{$btstype}{$region}{"cells"};
			$q_trx += $q_bts_trx_region{$btstype}{$region}{"trx"};
			$tot_reg{"cell"}{$region} += $q_bts_trx_region{$btstype}{$region}{"cells"};
			$tot_reg{"site"}{$region} += $q_bts_trx_region{$btstype}{$region}{"site"};
			$tot_reg{"trx"}{$region} += $q_bts_trx_region{$btstype}{$region}{"trx"};
			
		}
		else {
			print RFILE td(["","",""]);
		}
	}
	print RFILE td([$q_site,$q_for_this_type,$q_trx]);
	print RFILE "</TR>\n";
	$total_reg{"site"} += $q_site;
	$total_reg{"cell"} += $q_for_this_type;
	$total_reg{"trx"} += $q_trx;
}
print RFILE "<TR>\n";
print RFILE th("OMC Total");
foreach my $region (@regions) {
	print RFILE td([$tot_reg{"site"}{$region},$tot_reg{"cell"}{$region},$tot_reg{"trx"}{$region}]);
}
print RFILE td([$total_reg{"site"},$total_reg{"cell"},$total_reg{"trx"}]);
print RFILE "</TR>\n";
print RFILE end_table(),"<BR>\n";

print RFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print RFILE caption("Module Level"), "\n";
print RFILE Tr(th(["Type", @regions, "Network"])),"\n";
open(CIRC,"<".$config{"OUTPUT_CSV"}."CircuitQuantities.csv") || die "Cannot open CircuitQuantities.csv: $!\n";
while (<CIRC>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		s/\"//g;
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my $region = region($line{"BSC_NAME"});
		$region = 'Test' if ($line{"TYPE"} =~ /TEST/);
		$region = 'New' if ($line{"TYPE"} =~ /NEW/);
		$q_card_region{$line{"CircuitPackType"}}{$region} += $line{"Quantity"};
	}
}
close(CIRC) || die "Cannot close CircuitQuantities.csv: $!\n";

for my $cardtype (sort keys %q_card_region) {
	my $q_for_this_type = 0;
	print RFILE "<TR>";
	print RFILE th($cardtype);
	foreach my $region (@regions) {
		if (exists ($q_card_region{$cardtype}{$region})) {
			print RFILE td($q_card_region{$cardtype}{$region});
			$q_for_this_type += $q_card_region{$cardtype}{$region};
		}
		else {
			print RFILE td("");
		}
	}
	print RFILE td($q_for_this_type);
	print RFILE "</TR>\n";
}

print RFILE end_table(),"<BR>\n";
print RFILE end_html();
close RFILE;
print "END:Generating Regional Equipment Quantities\n";

#generate Network-Wide Quantity count
print "Generating Network Equipment Quantities\n";
open OUTFILE, ">$outpath"."q_network.html" or die "Cannot open $outpath"."q_network.html for writing! : $!\n";
print OUTFILE start_html(	-title=>"Network-wide Equipment Quantities",
			-author=>'rivanov@alcatel.co.za',
			-age=>'0',
			-meta=>{'http-equiv'=>'no-cache',
					'copyright'=>'R Ivanov'},
			-BGCOLOR=>(CLR_BG),
			-style=>{-code=>"$style"} );
print OUTFILE h3("Network-wide Equipment Quantities, generated ".scalar(localtime));
print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print OUTFILE caption("BSC Level"), "\n";
print OUTFILE Tr(th(["Type", (sort omcsort keys %ind), "Network"])),"\n";
my @omcs = sort omcsort keys %ind;
my %total_n = ();
for my $bsctype (sort keys %q_bsc) {
	my $q_for_this_type = 0;
	print OUTFILE "<TR>";
	print OUTFILE th($bsctype);
	for my $omc (@omcs) {
		if (exists ($q_bsc{$bsctype}{$omc})) {
			print OUTFILE td($q_bsc{$bsctype}{$omc});
			$total_n{$omc} += $q_bsc{$bsctype}{$omc};
			$q_for_this_type += $q_bsc{$bsctype}{$omc};
		}
		else {
			print OUTFILE td("");
		}
	}
	print OUTFILE td($q_for_this_type);
	$total_n{'Network'} += $q_for_this_type;
	print OUTFILE "</TR>\n";
}
print OUTFILE Tr(th(["Total",@total_n{@omcs},$total_n{'Network'}]));
print OUTFILE end_table(),"<BR>\n";

push(@omcs,'Test');
push(@omcs,'New');


print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print OUTFILE caption("BTS Level"), "\n";
print OUTFILE "<TR>";
print OUTFILE th("Type");
for my $omc (@omcs) {
	print OUTFILE th({-colspan=>3},"$omc");
}
print OUTFILE th({-colspan=>3},"Network Total");
print OUTFILE "</TR>\n";

print OUTFILE "<TR>";
print OUTFILE th("");
for my $omc (@omcs) {
	print OUTFILE th(["Sites","Cells","TRX"]);
}
print OUTFILE th(["Sites","Cells","TRX"]);
print OUTFILE "</TR>\n";
my %tot_omc = ();
my %totals = ();
for my $btstype (sort keys %q_bts) {
	my $q_for_this_type = 0;
	my $q_site = 0;
	my $q_trx = 0;
	
	print OUTFILE "<TR>";
	print OUTFILE th($btstype);
	for my $omc (@omcs) {
		if (exists ($q_bts{$btstype}{$omc})) {
			print OUTFILE td([$q_bts_trx{$btstype}{$omc}{"site"},$q_bts_trx{$btstype}{$omc}{"cells"},$q_bts_trx{$btstype}{$omc}{"trx"}]);
			$q_for_this_type += $q_bts_trx{$btstype}{$omc}{"cells"};
			$q_site += $q_bts_trx{$btstype}{$omc}{"site"};
			$q_trx += $q_bts_trx{$btstype}{$omc}{"trx"};
			$tot_omc{"cell"}{$omc} += $q_bts_trx{$btstype}{$omc}{"cells"};
			$tot_omc{"site"}{$omc} += $q_bts_trx{$btstype}{$omc}{"site"};
			$tot_omc{"trx"}{$omc} += $q_bts_trx{$btstype}{$omc}{"trx"};
			
		}
		else {
			print OUTFILE td(["","",""]);
		}
	}
	print OUTFILE td([$q_site,$q_for_this_type,$q_trx]);
	print OUTFILE "</TR>\n";
	$totals{"site"} += $q_site;
	$totals{"cell"} += $q_for_this_type;
	$totals{"trx"} += $q_trx;
}
print OUTFILE "<TR>\n";
print OUTFILE th("OMC Total");
for my $omc (@omcs) {
	print OUTFILE td([$tot_omc{"site"}{$omc},$tot_omc{"cell"}{$omc},$tot_omc{"trx"}{$omc}]);
}
print OUTFILE td([$totals{"site"},$totals{"cell"},$totals{"trx"}]);
print OUTFILE "</TR>\n";
print OUTFILE end_table(),"<BR>\n";

print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print OUTFILE caption("Module Level"), "\n";
print OUTFILE Tr(th(["Type", (@omcs), "Network"])),"\n";
open(CIRC,"<".$config{"OUTPUT_CSV"}."CircuitQuantities.csv") || die "Cannot open CircuitQuantities.csv: $!\n";
while (<CIRC>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		s/\"//g;
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		my $OMC = $omc{$line{"OMC_ID"}};
		$OMC = 'Test' if ($line{'TYPE'} =~ /TEST/);
		$OMC = 'New' if ($line{'TYPE'} =~ /NEW/);
		$q_card{$line{"CircuitPackType"}}{$OMC} += $line{"Quantity"};
	}
}
close(CIRC) || die "Cannot close CircuitQuantities.csv: $!\n";

for my $cardtype (sort keys %q_card) {
	my $q_for_this_type = 0;
	print OUTFILE "<TR>";
	print OUTFILE th($cardtype);
	for my $omc (@omcs) {
		if (exists ($q_card{$cardtype}{$omc})) {
			print OUTFILE td($q_card{$cardtype}{$omc});
			$q_for_this_type += $q_card{$cardtype}{$omc};
		}
		else {
			print OUTFILE td("");
		}
	}
	print OUTFILE td($q_for_this_type);
	print OUTFILE "</TR>\n";
}


print OUTFILE end_table(),"<BR>\n";
print OUTFILE end_html();
close OUTFILE;
print "END: Generating Network Equipment Quantities\n";


##create BCCH on multiRate HTML
open(BCMUL,"<".$config{"OUTPUT_CSV"}."bcchMultiRate.csv") || die "Cannot open bcchMultiRate.csv: $!\n";
print "Generating BCCH on multiRate RSL HTML\n";
open OUTFILE, ">$outpath"."multi_bcch.html" or die "Cannot open $outpath"."multi_bcch.html for writing! : $!\n";
print OUTFILE start_html(	-title=>"Sites with a BCCH configured on a multirate RSL",
			-author=>'hartmut.behrens@alcatel.co.za',
			-age=>'0',
			-meta=>{'http-equiv'=>'no-cache',
					'copyright'=>'H Behrens'},
			-BGCOLOR=>(CLR_BG),
			-style=>{-code=>"$style"} );
print OUTFILE h3("Sites with BCCH configured on a multirate RSL");
print OUTFILE h3("Generated ".scalar(localtime));
print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print OUTFILE Tr(th(["OMC","BSC","SITE","LAC","CI","RSL","TRX"])),"\n";
my $bcMulTotal = 0;
while (<BCMUL>) {
	chomp;
	if ($. == 1) {				#load header line
		@cols = split(/;/,$_);
	}
	else {
		my @data = split(/;/,$_);
		@line{@cols} = @data;
		print OUTFILE Tr(td([@line{qw/OMC_ID BSC_NAME SITE LAC CI RSL TRX/}])),"\n";
		$bcMulTotal++;
	}
}
print OUTFILE end_table(),"<BR>\n";
print OUTFILE end_html();
close OUTFILE;
close BCMUL;
print "END:Generating BCCH on multiRate RSL HTML\n";
##END BCCH on multiRate
# now create zips
print "Creating ZIP files\n";
if ($^O =~ /mswin/i) {
	# under windows? forget it
	chdir($outpath);
}
else {
	my $cmd = "/usr/bin/zip $archpath"."/config/config_$year".sprintf("%02d%02d",$mon,$mday).".zip $outpath\*.html";
	#print "1:",$cmd,"\n";
	`$cmd`;
	
	for my $omc (keys %ind) {
		my @conf = ();
		if (exists($ind{$omc})) {
			foreach my $mfs (keys %{$ind{$omc}}) {
				push(@conf,$mfs);
				my @bsc = keys %{$ind{$omc}{$mfs}};
				push(@conf,@bsc);
			}
		}
		if (exists($a925_ind{$omc})) {
			push(@conf,@{$a925_ind{$omc}});
		}
		chdir($outpath);
		my $cmd = "/usr/bin/zip conf_$omc.zip ".join(".html ",@conf).".html";
		`$cmd`;
#		#print "2:",$cmd,"\n";
	}
	$cmd = "/usr/bin/zip $archpath"."/quantity/quantity_$year-".sprintf("%02d-%02d",$mon,$mday).".zip $outpath"."q_network.html";
	`$cmd`;
}

# now dump an index
#first read SLD package names, since we will have to link to them from the index page
my @sld_files;
foreach my $omc (@{$aref}) {
	my $ftp = Net::FTP->new($href->{'OMC'.$omc.'_IP'}, Debug => 0);
	$ftp->login($href->{'OMC'.$omc.'_USERNAME'},$href->{'OMC'.$omc.'_PASSWORD'});
	my @sld = grep {/tar.gz/} $ftp->ls($href->{'OMC'.$omc.'_SLDDIR'});
	push @sld_files, @sld;
}
my $sld_files = join(' ',@sld_files);

print "Creating Index HTML\n";
open OUTFILE, ">bssIndex.html" or die "Cannot open $outpath"."bssIndex.html for writing! : $!\n";
print OUTFILE start_html(	-title=>"Config Sheet Index",
			-author=>'rivanov@alcatel.co.za',
			-age=>'0',
			-meta=>{'http-equiv'=>'no-cache',
					'copyright'=>'R Ivanov'},
			-BGCOLOR=>(CLR_BG),
			-style=>{-code=>"$style"});
print OUTFILE h3("Configuration Sheet Index");

print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print OUTFILE caption("Configuration Sheets"), "\n";
print OUTFILE caption("$emlCount EML[hardware] out of $rnlCount RNL[logical] BSC's found"), "\n";
print OUTFILE Tr(th([sort omcsort keys %ind])),"\n";

print OUTFILE "<TR>";
foreach (keys %ind) {
	print OUTFILE th("MFS/BSC");
}
print OUTFILE "</TR>\n";
my $full = 1;
my %printed = ();
while ($full) {
	print OUTFILE "<TR>";
	$full = 0;
	foreach my $omc (sort omcsort keys %ind) {
		my @mfs = sort keys %{$ind{$omc}};
		if (exists $mfs[0]) {
			my @bsc = sort bscsort keys %{$ind{$omc}{$mfs[0]}};
			if (exists($printed{$mfs[0]})) {
				my $sld = undef;
				$sld = $1 if ($sld_files =~ /($bsc[0].*?tar.gz)/);
				if ($sld) {
					print OUTFILE td(a({href=>"$bsc[0].html"},$bsc[0]),' ',a({href=>'ftp://'.$omc.'.vodacom.co.za/SLD/'.$sld},'SLD'));
				}
				else {
					print OUTFILE td(a({href=>"$bsc[0].html"},$bsc[0]));
				}
				#print OUTFILE td('<a href="ftp://'.$omc.'.vodacom.co.za/SLD/'.$bsc[0].'.tar.gz>SLD</a>');
				delete $ind{$omc}{$mfs[0]}{$bsc[0]};
			}
			else {
				print OUTFILE td({-class=>'mfs'},a({href=>"$mfs[0].html"},$mfs[0]));
			}
			$printed{$mfs[0]} = 1;
			delete $ind{$omc}{$mfs[0]} unless (keys %{$ind{$omc}{$mfs[0]}});
			$full++;
		}
		else {
			print OUTFILE td("");
			#$full = 0;
		}
	}
	print OUTFILE "</TR>\n";
}

print OUTFILE "<TR>";
foreach (keys %ind) {
	print OUTFILE th("A925");
}
print OUTFILE "</TR>\n";


$full = 1;
while ($full) {
	#$full  = scalar(keys %a925_ind);
	$full = 0;
	print OUTFILE "<TR>";
	#for my $omc (sort omcsort keys %a925_ind) {
	#print "A925 OMC is $omc\n";	
	foreach my $omc (sort omcsort keys %ind) {
		if ((exists $a925_ind{$omc}) && (scalar @{$a925_ind{$omc}})) {
			@{$a925_ind{$omc}} = sort @{$a925_ind{$omc}};
			my $tc = shift(@{$a925_ind{$omc}});
			print OUTFILE td(a({href=>"$tc.html"},$tc));
			$full++;
		}
		else {
			print OUTFILE td("");
		}
		
	}
	print OUTFILE "</TR>\n";
}


print OUTFILE "<TR>";
print OUTFILE "</TR>\n";
print OUTFILE "<TR>";

foreach (keys %ind) {
	print OUTFILE th("Configuration");
}
print OUTFILE "</TR>\n";
print OUTFILE "<TR>";
for my $omc (sort omcsort keys %ind) {
	print OUTFILE td(a({href=>"conf_$omc.zip"},"all above, zipped"));
}
print OUTFILE "</TR>\n";
print OUTFILE end_table(),"<BR>\n";

print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>0}),"\n";
print OUTFILE caption("Equipment Quantities"), "\n";
print OUTFILE Tr(td([a({href=>"AlcatelEIS.html"},"Alcatel Element Count"),a({href=>"q_network.html"},"Network Wide"),a({href=>"q_regional.html"},"Regional")])),"\n";
print OUTFILE end_table(),"<BR>\n";

print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>0}),"\n";
print OUTFILE caption("Summary Reports"), "\n";
print OUTFILE Tr(td([a({href=>"bscConfig.html"},"BSC Setup"),a({href=>"tcSummary.html"},"Transcoders"),a({href=>"mfs_config.html"},"MFS Setup")])),"\n";
print OUTFILE end_table(),"<BR>\n";


print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>0}),"\n";
print OUTFILE caption("Remote Inventory"), "\n";
print OUTFILE Tr(td([a({href=>"../risheets/"},"Remote Inventory Sheets")])),"\n";
print OUTFILE end_table(),"<BR>\n";

print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print OUTFILE caption("Diagnostics"), "\n";
print OUTFILE Tr(td({-colspan=>scalar(keys %ind)},[a({href=>"SDCCH_TCU_LOAD.html"},"High SDCCH Load on TCU ($sdTotal)"),a({href=>"ABIS_ALARM_DISABLED.html"},"A-bis Alarm Reporting Disabled ($a1,$a2,$a3,$a4)"),
							a({href=>"multi_bcch.html"},"BCCH on MultiRate ($bcMulTotal)")])),"\n";
print OUTFILE Tr(td({-colspan=>scalar(keys %ind)},[a({href=>"g2ParameterComparison.html"},"G2 BSC Parameter Comparison"),"",a({href=>"mxParameterComparison.html"},"Mx BSC Parameter Comparison")])),"\n";
print OUTFILE end_table(),"<BR>\n";


print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print OUTFILE caption("Downloads"), "\n";
print OUTFILE Tr(td({-colspan=>scalar(keys %ind)},a({href=>"../confsheets/history/"},"Browse the Directory"))),"\n";

print OUTFILE end_table(),"<BR>\n";
print OUTFILE end_html();
close OUTFILE;

open FRAMEINDEX, ">index.html" or die "Cannot open $outpath"."index.html for writing! : $!\n";
print FRAMEINDEX "<FRAMESET ROWS=\"30%,70%\">","\n";
print FRAMEINDEX "<FRAME SRC=\"\.\./cgi-bin/goFind.pl\">","\n";
print FRAMEINDEX "<FRAME SRC=\"bssIndex.html\">","\n";
print FRAMEINDEX "</FRAMESET>\n";
close FRAMEINDEX;
print "END: Creating Index HTML\n";

print "END: Creating ZIP files\n";
print "__DONE__\n";


sub omcsort {
	$a =~ /(\d)$/;
	my $omc1 = $1;
	$b =~ /(\d)$/;
	return ($omc1 cmp $1);
}

#sort according to first and then last four characters of BSC name
sub bscsort {
	my $reg_a = substr($a,0,1);
	my $reg_b = substr($b,0,1);
	my $bsc_a = substr($a,-4);
	my $bsc_b = substr($b,-4);
	return ($reg_a cmp $reg_b) || ($bsc_a cmp $bsc_b);
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

