#!/usr/bin/perl -w

# 2004 by Hartmut Behrens (##)
# Assembles BSC config data for all BSC's
use strict;
use warnings;
use CGI qw(-no_debug :standard :html3 *table);

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
my $archpath = $config{"OUTPUT_HISTORY"};

my %emlBsc = (
	"AlcatelBscInstanceIdentifier"	=>1,
	"BSC_Generation"		=>1,
	"BSC_HW_Config"			=>1,
	"UserLabel"			=>1,
	"IMPORTDATE"			=>1
	);

my %n7 = (
	"AlcatelSignLinkN7InstanceIdentifier"	=>1,
	"UserLabel"				=>1
	);
my %n7Align = ();
my %problem = ();
my %type = ();
my $lastDate = '0000-00-00';

print "--Compiling BSC Config Information--\n";
loadACIE("AlcatelBsc","eml",\%emlBsc);
my %bscConfig = ();
my ($bscId);
foreach my $omc (keys %emlBsc) {
	foreach my $id (keys %{$emlBsc{$omc}}) {
		($bscId) = ($id =~ /amecID\s(\d+)/);
		@{$bscConfig{$omc}{$bscId}}{qw/NAME GEN CONFIG IMPORTDATE/} = @{$emlBsc{$omc}{$id}}{qw/UserLabel BSC_Generation BSC_HW_Config IMPORTDATE/};
	}
}


loadACIE("AlcatelSignLinkN7","eml",\%n7);
foreach my $omc (keys %n7) {
	foreach my $id (keys %{$n7{$omc}}) {
		my ($bscid) = ($id =~ /amecID\s(\d+)/);
		my $bscName = $bscConfig{$omc}{$bscid}{'NAME'};
		$bscName =~ s/\"//g;
		$type{$bscName} = $bscConfig{$omc}{$bscid}{'CONFIG'};
		$lastDate = $bscConfig{$omc}{$bscid}{'IMPORTDATE'};
		my ($slc) = ($id =~ /moiRdn\s(\d+)/);
		my $label = $n7{$omc}{$id}{'UserLabel'};
		$label =~ s/\"//g;
		$n7Align{$omc}{$bscName}{$slc} = $label;
		my $correct = ($slc*4) + 1;
		$correct = 'N7 '.$correct;
		if ($correct ne $label) {
			$problem{$omc}{$bscName} = 1;
		}
	}
}

#create the HTML report
mkdir("$archpath"."n7AlignCheck/") unless (-e "$archpath"."n7AlignCheck/");
open OUTFILE, ">$archpath"."n7AlignCheck/"."n7Check_".$lastDate.".html" or die "Cannot open file for writing! : $!\n";
print OUTFILE start_html(	-title=>"N7 Alignment Check for $lastDate",
		-author=>'hartmut.behrens@alcatel.co.za',
		-age=>'0',
		-meta=>{'http-equiv'=>'no-cache',
				'copyright'=>'H Behrens'},
		-BGCOLOR=>(CLR_BG),
		-style=>{-code=>"$style"});
print OUTFILE h3("N7 Alignment check for $lastDate");
print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
print OUTFILE caption("Summary - BSC\'s with misaligned N7");
print OUTFILE Tr(th(["BSC","BSC Type","SLC\'s","N7 Mapping"]));
foreach my $omc (sort keys %problem) {
	foreach my $bsc (sort keys %{$problem{$omc}}) {
		my @slc = sort {$a <=> $b} keys %{$n7Align{$omc}{$bsc}};
		my @n7 = @{$n7Align{$omc}{$bsc}}{@slc};
		my ($slCell,$n7Cell) = showAlign(\@slc,\@n7);
		print OUTFILE Tr(td([$bsc,$type{$bsc},$slCell,$n7Cell]));
	}
}
print OUTFILE end_table(),"<BR>\n";
print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
print OUTFILE caption("Details");
print OUTFILE Tr(th(["BSC","BSC Type","SLC\'s","N7 Mapping"]));
foreach my $omc (sort keys %n7Align) {
	foreach my $bsc (sort keys %{$n7Align{$omc}}) {
		my @slc = sort {$a <=> $b} keys %{$n7Align{$omc}{$bsc}};
		my @n7 = @{$n7Align{$omc}{$bsc}}{@slc};
		my ($slCell,$n7Cell) = showAlign(\@slc,\@n7);
		print OUTFILE Tr(td([$bsc,$type{$bsc},$slCell,$n7Cell]));
	}
}
print OUTFILE end_table(),"<BR>\n";
close OUTFILE;


#print a table cell to show (in color ) n7 Alignment problems
sub showAlign {
	my ($slRef,$n7Ref)  = @_;
	my $slCell = undef;
	my $n7Cell = undef;
	
	my $rv1 = "\n".start_table({ -align=>'center', -cellpadding=>0,-border=>0})."\n";
	my $rv2 = "\n".start_table({ -align=>'center', -cellpadding=>0,-border=>0})."\n";
	for (0..$#{$slRef}) {
		my $correct = 'N7 '.(($slRef->[$_]*4)+1);
		my $actual = $n7Ref->[$_];
		if ($correct eq $actual) {
			$slCell .= td($slRef->[$_]);
			$n7Cell .= td($n7Ref->[$_]);
		}
		else {
			$slCell .= td({-style=>"background-color: rgb(255,0,0)"},$slRef->[$_]);
			$n7Cell .= td({-style=>"background-color: rgb(255,0,0)"},$n7Ref->[$_]);
		}
		
	}
	$rv1 .=  Tr($slCell)."\n";
	$rv1 .= end_table()."\n";
	$rv2 .=  Tr($n7Cell)."\n";
	$rv2 .= end_table()."\n";
	return ($rv1,$rv2);
}



__END__
