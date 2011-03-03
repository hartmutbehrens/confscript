#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# create a csv file detailing reoccuring A-channel failures

use strict;
use warnings;
use CGI qw(-no_debug :standard :html3 *table);
use File::Copy;

my %config = ();
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
%config = %{$href};
require "loadACIEsubs.pl";

# HTML settings
use constant CLR_BG_TH		=> "#dcdcdc";
use constant CLR_BG_TD		=> "#FFFFFF";
use constant CLR_BG_TD_ARG	=> "#e0ffff";
use constant CLR_FONT		=> "#000000";
use constant CLR_RED		=> "#FF9999";
use constant CLR_BRIGHT_RED	=> "#FF0000";
use constant CLR_BLUE		=> "#AFEEEE";
use constant CLR_GREEN		=> "#98FB98";
use constant CLR_BG		=> "#77ccff";
use constant CLR_D_BAD_CNT	=> "#ff0000";
use constant CLR_D_QUESTIONS	=> "#ffff00";
use constant CLR_D_STUCK	=> "#ffa500";
use constant CLR_D_PRESENT	=> "#90ee90";
use constant CLR_D_EMPTY	=> "#d3d3d3";
use constant TABLE_WIDTH	=> 780;
use constant CELL_NAME_SIZE	=> 18;

my $style = 	"p {font-size: 75%; font-family: sans-serif; text-align: center}\n".
				"h2 {font-family: sans-serif; font: italic; text-align: center}\n".
				"h3 {font-family: sans-serif; font: italic; text-align: center}\n".
				"th {background: ".(CLR_BG_TH)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif}\n".
				"td {background-color: ".(CLR_BG_TD)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif; text-align: center}\n".
				"td.blank {background: transparent;}\n".
				"td.etcu {background-color: ".(CLR_GREEN).";}\n".
				"td.mrate {background-color: ".(CLR_BLUE).";}\n".
				"td.sdhigh {color: ".(CLR_BRIGHT_RED)."; font: bold;}\n".
				"td.sdhighmrate {background-color: ".(CLR_BLUE)."; color: ".(CLR_BRIGHT_RED)."; font: bold;}\n".
				"td.mtrx {background-color: ".(CLR_RED).";}\n".
				"table.cl {width: \"100%\"; border: 0; cellspacing: 0; cellpadding: 0}\n".
				"caption {font-family: sans-serif; font: bold italic; font-size: 75%; text-align: center}\n";



print "--Creating A-Channel Status Report--\n";	
my %ttp = (
		'Alcatel2MbTTPInstanceIdentifier'	=>1,
		'AdministrativeState'			=>1,
		'ListOfTsNotUsedForTraffic'		=>1,
		'ListOfAChannels'			=>1,
		'AdministrativeState'			=>1,
		'TTPtype'				=>1,
		'TtpNumber'				=>1,
		);
my %emlBsc = (
	"AlcatelBscInstanceIdentifier"	=>1,				#only load these columns
	"UserLabel"			=>1,
	"IMPORTDATE"			=>1
	);
loadACIE("Alcatel2MbTTP","eml",\%ttp);
&loadACIE("AlcatelBsc","eml",\%emlBsc);
my $achpath = "/var/www/html/confsheets/history/achannel/";
my $ach2path = "/var/www/html/confsheets/achannel/";

my $date = '0000-00-00';
#quickly get date from BSC export
foreach my $omc (keys %emlBsc) {
	foreach my $id (keys %{$emlBsc{$omc}}) {
		$date = $emlBsc{$omc}{$id}{"IMPORTDATE"};
		last;
	}
	last;
}

open AFILE, ">".$config{"OUTPUT_CSV"}."achproblem_$date.html" or die "Cannot open achproblem_$date.html for writing! : $!\n";
print AFILE start_html(	-title=>"A - Channels not enabled ($date)",
			-author=>'hartmut.behrens@alcatel.co.za',
			-age=>'0',
			-meta=>{'http-equiv'=>'no-cache',
				'copyright'=>'ASA'},
			-BGCOLOR=>(CLR_BG),
			-style=>{-code=>"$style"} );
print AFILE h3("A - Channels not enabled ($date)");
print AFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
print AFILE caption("A - Channel Problems"), "\n";
print AFILE Tr(th(["OMC","BSC","A Trunk","TimeSlot","Administrative State","Operational State","Availability"])),"\n";
my %achBsc = ();					#hold a-channel problem indications per BSC
foreach my $omc (keys %ttp) {
	foreach my $id (sort keys %{$ttp{$omc}}) {
		next if not($ttp{$omc}{$id}{"TTPtype"} =~ /ater$/);
		next if ($ttp{$omc}{$id}{"AdministrativeState"} =~ /^locked/);
		my $notUsed = $ttp{$omc}{$id}{"ListOfTsNotUsedForTraffic"};
		my $tt = $ttp{$omc}{$id}{"TtpNumber"};
		my $achannels = $ttp{$omc}{$id}{"ListOfAChannels"};
		my @used_ts = ($notUsed =~ /(\d+)/g);
		
		my ($bscId,$moId) = ($id =~ /\{\sameID\s(\{.*?moiRdn\s(\d+)\}).*?/);
		next if ($moId != 1);		#only interested in BSC tp's
		my $bscName = $emlBsc{$omc}{$bscId}{'UserLabel'};
		($bscName) =~ s/\"//g;
		my ($tsRef,$adminRef,$opRef,$availRef) = &process_list_of_a_channels($achannels);
		foreach my $ts (@{$tsRef}) {
			my $adState = ${$adminRef}[$ts];
			my $opState = ${$opRef}[$ts];
			my $availState = ${$availRef}[$ts] || '0';
			my $inUse = 0;
			$inUse = 1 if defined($used_ts[$ts]);
			if (($adState eq 'locked') or ($opState eq 'disabled') or ($availState == 1)) {
				$achBsc{$omc}{$bscName}{$tt}{$ts}{'AdminState'} = $adState;
				$achBsc{$omc}{$bscName}{$tt}{$ts}{'OpState'} = $opState;
				print AFILE "<TR>";
				print AFILE td([$omc,$bscName,$tt,$ts,$adState,$opState ]);
				if ($availState == 1)	{
					print AFILE td("failed");
					$achBsc{$omc}{$bscName}{$tt}{$ts}{'AvailState'} = 'failed';
				}
				else {
					print AFILE td("");
					$achBsc{$omc}{$bscName}{$tt}{$ts}{'AvailState'} = '-';
				}
				print AFILE "</TR>\n";
			}
		}
		
	}
}
print AFILE end_table(),"<BR>\n";
close AFILE;
move($config{"OUTPUT_CSV"}."achproblem_".$date.".html",$achpath."achproblem_".$date.".html");
#spool a A-channel report per BSC
#  0    1    2     3     4    5     6     7     8
my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) =  localtime(time);
$year+=1900;
$mon+=1;
$mday-=2;	#need yesterday's date w.r.t. ACIE export
my $yesterday = "$year"."-".sprintf("%02d",$mon)."-"."$mday\n";
open ASUM, ">".$config{"OUTPUT_CSV"}."aChsum.csv" or die "Cannot open aChsum.csv for writing! : $!\n";
foreach my $omc (keys %emlBsc) {
	foreach my $bsc (keys %{$emlBsc{$omc}}) {
		my $bscName = $emlBsc{$omc}{$bsc}{'UserLabel'};
		($bscName) =~ s/\"//g;
		open AFILE, ">".$config{"OUTPUT_CSV"}."achproblem_".$bscName."_".$date.".html" or die "Cannot open achproblem".$bscName."_$date.html for writing! : $!\n";
		print AFILE start_html(	-title=>"A - Channels not enabled for BSC $bscName ($date)",
			-author=>'hartmut.behrens@alcatel.co.za',
			-age=>'0',
			-meta=>{'http-equiv'=>'no-cache',
				'copyright'=>'ASA'},
			-BGCOLOR=>(CLR_BG),
			-style=>{-code=>"$style"} );
		print AFILE h3("A - Channels not enabled for BSC $bscName ($date)");
		print AFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
		print AFILE Tr(td({-class=>'blank',-align=>'CENTER'},a({href=>"../achannel/achproblem_".$bscName."_".$yesterday.".html"},"Yesterday's problems") ));
		print AFILE end_table(),"<BR>\n";
		#print AFILE a({href=>"../achannel/achproblem_".$bscName."_".$yesterday.".html"},"Yesterday's problems");
		print AFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
		print AFILE caption("A - Channel Problems"), "\n";
		print AFILE Tr(th(["OMC","BSC","A Trunk","TimeSlot","Administrative State","Operational State","Availability"])),"\n";
		my $aChFailures = 0;
		foreach my $tp (sort keys %{$achBsc{$omc}{$bscName}}) {
			foreach my $ts (sort keys %{$achBsc{$omc}{$bscName}{$tp}}) {
				$aChFailures++;
				my $adState = $achBsc{$omc}{$bscName}{$tp}{$ts}{'AdminState'};
				my $opState = $achBsc{$omc}{$bscName}{$tp}{$ts}{'OpState'};
				my $availState = $achBsc{$omc}{$bscName}{$tp}{$ts}{'AvailState'};
				print AFILE Tr(td([$omc,$bscName,$tp,$ts,$adState,$opState,$availState])),"\n";
			}
		}
		print AFILE end_table(),"<BR>\n";
		close AFILE;
		move($config{"OUTPUT_CSV"}."achproblem_".$bscName."_".$date.".html",$ach2path."achproblem_".$bscName."_".$date.".html");
		print ASUM "$bscName;$aChFailures\n";
	}
}
close ASUM;
print "--END:Creating A-Channel Status Report:END--\n";	

sub process_list_of_a_channels {
	my ($ach_list) = @_;
	my @rv_TS = ();
	my @rv_adminState = ();
	my @rv_opState = ();
	my @rv_availState = ();
	my $pattern = "{ tsNumber\\s(\\d+).*?administrativeState\\s(.*?),\\soperationalState\\s(.*?),\\savailabilityStatus\\s{(.*?)},\\scontrol";
	while ($ach_list =~ /$pattern/g) {
		push(@rv_TS,$1);
		push(@rv_adminState,$2);
		push(@rv_opState,$3);
		push(@rv_availState,$4);
	}
	return (\@rv_TS,\@rv_adminState,\@rv_opState,\@rv_availState);
}



__END__
