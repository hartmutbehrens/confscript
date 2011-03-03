#!/usr/bin/perl -w

# 2005 by Hartmut Behrens (##)
use strict;
use warnings;
use CGI qw(-no_debug :standard :html3 *table);
use File::Copy;


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
my $date = '0000-00-00';

	
my %cell = (
	"CellInstanceIdentifier" => 1,
	"CellGlobalIdentity"	=> 1,
	"AGprsMinPdch" => 1,
	"AGprsMaxPdch" => 1,
	"AGprsMaxPdchHighLoad" => 1,
	"RnlSupportingSector" => 1,
	"EnGprs"	=> 1,
	"UserLabel"	=> 1
	);

my %sct = (
	"RnlAlcatelSectorInstanceIdentifier" => 1,
	"NbBaseBandTransceiver"	=> 1
	);
	
my %bsc = (
	"RnlAlcatelBSCInstanceIdentifier" => 1,
	"IMPORTDATE" => 1,
	"UserLabel" => 1
	);

loadACIE("RnlAlcatelBSC","rnl",\%bsc);
loadACIE("RnlAlcatelSector","rnl",\%sct);
loadACIE("Cell","rnl",\%cell);


foreach	my $omc (keys %cell) {
	foreach my $id (keys %{$cell{$omc}}) {
		next if ($cell{$omc}{$id}{'EnGprs'} eq 'FALSE');
		my $rnlId = $cell{$omc}{$id}{'RnlSupportingSector'};
		my ($ci) = ($cell{$omc}{$id}{'CellGlobalIdentity'} =~ /ci\s(\d+)/);
		my ($bscId) = ($rnlId =~ /bsc\s(\d+)/);
		my $bscN = $bsc{$omc}{$bscId}{'UserLabel'};
		$bscN =~ s/\"//g;
		$date = $bsc{$omc}{$bscId}{'IMPORTDATE'};
		my $rg = region($bscN);
		my $bbt = $sct{$omc}{$rnlId}{'NbBaseBandTransceiver'};
		@{$rep{$rg}{$bscN}{$ci}}{qw/NAME MINPDCH MAXPDCH_HIGHLOAD MAXPDCH/} = @{$cell{$omc}{$id}}{qw/UserLabel AGprsMinPdch AGprsMaxPdchHighLoad AGprsMaxPdch/};
		$rep{$rg}{$bscN}{$ci}{'NAME'} =~ s/\"//g;
		$rep{$rg}{$bscN}{$ci}{'TRX'} = $bbt;
	}
}



my @wrd = qw/NAME TRX MINPDCH MAXPDCH_HIGHLOAD MAXPDCH/;

open OUTFILE, ">gprsRep.html" or die "Cannot open gprsRep.html for writing! : $!\n";
print OUTFILE start_html(-title=>"GPRS Configuration Report",-author=>'hartmut.behrens@alcatel.co.za',-age=>'0',-BGCOLOR=>(CLR_BG),-style=>{-code=>"$style"});
print OUTFILE h3("GPRS Configuration Report");
print OUTFILE "Based on OMC export of $date<br>";
#shortcuts to regions
print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
foreach my $r (sort keys %rep) {
	print OUTFILE Tr(td({-class=>'blank',-align=>'LEFT'},ul(li([a({-href=>"#$r"},"Go to ".$r)]))));
}
print OUTFILE end_table(),"<BR>\n";
foreach my $r (sort keys %rep) {
	print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
	print OUTFILE caption(a({-name=>"$r"},"$r GPRS Configuration Report"));
	print OUTFILE Tr(th(['BSC','CI',@wrd]));
	foreach my $bsc (keys %{$rep{$r}}) {
		foreach my $ci (keys %{$rep{$r}{$bsc}}) {
			print OUTFILE Tr(td([$bsc,$ci,@{$rep{$r}{$bsc}{$ci}}{@wrd}]));
		}
	}
	print OUTFILE end_table(),"<br><br>";
}
print OUTFILE end_html();
close OUTFILE;
copy('gprsRep.html','/var/www/html/confsheets/gprsRep.html');

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