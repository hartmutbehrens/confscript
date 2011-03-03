#!/usr/bin/perl -w

# 2008 by Hartmut Behrens (##)
# compare BSC parameters
use strict;
use warnings;
use XML::Simple;
use Data::Dumper;
use File::Copy;
use CGI qw(-no_debug :standard :html3 *table);
use Getopt::Std;

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


require "loadACIEsubs.pl";
my $fileName = 'bscParameterComparison.html';
my %prm = ();
my %args = ();
my $params = XMLin('etc/parameters.xml',forcearray => 1);
getopt("fbt",\%args);
$fileName = $args{'f'} if defined($args{'f'});

my %emlBsc = ();
my %rnlBsc = ();
my %hasThese = ();
my $date = '0000';
loadACIE('AlcatelBsc','eml',\%emlBsc);
loadACIE('RnlAlcatelBSC','rnl',\%rnlBsc);

my %bsc = ();
foreach my $o (keys %emlBsc) {
	foreach my $id (keys %{$emlBsc{$o}}) {
		my $label = $emlBsc{$o}{$id}{'UserLabel'};
		$label =~ s/\"//g;
		@{$bsc{$label}}{keys %{$emlBsc{$o}{$id}}} = values %{$emlBsc{$o}{$id}};
		@hasThese{keys %{$emlBsc{$o}{$id}}} = keys %{$emlBsc{$o}{$id}};
		$date = $emlBsc{$o}{$id}{'IMPORTDATE'};
	}
}

foreach my $o (keys %rnlBsc) {
	foreach my $bscId (keys %{$rnlBsc{$o}}) {
		my $label = $rnlBsc{$o}{$bscId}{'UserLabel'};
		$label =~ s/\"//g;
		@{$bsc{$label}}{keys %{$rnlBsc{$o}{$bscId}}} = values %{$rnlBsc{$o}{$bscId}};
		@hasThese{keys %{$rnlBsc{$o}{$bscId}}} = keys %{$rnlBsc{$o}{$bscId}};
	}
}
my @bsc = sort keys %bsc;

#compile the list of parameters to be checked.
my $refBsc = defined($args{'b'}) ? defined($bsc{$args{'b'}}) ? $args{'b'} : $bsc[0] : $bsc[0];
my @prmNames = ();
my %default = ();
my %cref = ();
foreach my $p (keys %{$params->{'parameter'}}) {
	if ($params->{'parameter'}->{$p}->{'check'} == 1) {
		my ($hmi,$cat,$default) = @{$params->{'parameter'}->{$p}}{qw/hmi_name category default/};
		if (exists($hasThese{$p})) {
			push(@prmNames,$p);
			$default{$p} = $default;
			$cref{$p} = $bsc{$refBsc}{$p};
		}
		else {
			#parameters that could not be found in the ACIE export.
		}
	}
	else {
		#parameters which should not be checked: check="0" in parameters.xml
	}
}

#parameter checks
#1. BSC parameter = ALU default; BSC parameter = Voda default (ST01 parameters)
#2. BSC parameter = ALU default; BSC parameter != Voda default (ST01 parameters)
#3. BSC parameter != ALU default; BSC parameter = Voda default (ST01 parameters)
#3. BSC parameter != ALU default; BSC parameter != Voda default (ST01 parameters)

my %results = ();
foreach my $p (@prmNames) {
	my $cat = $params->{'parameter'}->{$p}->{'category'};
	foreach my $bsc (@bsc) {
		if (defined $args{'t'}) {
			next if !($bsc{$bsc}{'BSC_Generation'} =~  /$args{t}/i);
		}
		if (not exists($bsc{$bsc}{$p})) {
			next;
		}
		#$results{'BSC=ALU_DEFAULT'}{$p}{$bsc} = ($bsc{$bsc}{$p} eq $default{$p}) ? 'YES' : 'NO';
		my $res = ($bsc{$bsc}{$p} eq $cref{$p}) ? 'EQUAL' : 'DIFFERENT';
		$results{$cat}{$res}{$p}{$bsc} = $cref{$p}.';'.$bsc{$bsc}{$p};
		#$results{'ALU_DEFAULT=REF_VALUE'}{$p}{$bsc} = ($default{$p} eq $cref{$p}) ? 'YES' : 'NO';
	}
}

my @pcol = ('Category','Parameter Name','HMI Name','BSC\'s that differ from reference','Reference value','Actual values');
open (OUTFILE, '>'.$fileName) || die "Cannot open $fileName for writing! : $!\n";
print OUTFILE start_html(-title=>"ALU Paramter Check Report",-author=>'hartmut.behrens@alcatel.co.za',-age=>'0',-BGCOLOR=>(CLR_BG),-style=>{-code=>"$style"});
print OUTFILE h3("ALU Parameter Check Report");
print OUTFILE h4("Parameters are compared against reference BSC ($refBsc), based on OMC-R export of $date<br>");
print OUTFILE start_table({-align=>"CENTER", -border=>0,-cellpadding=>2, -cellspacing=>1}),"\n";
print OUTFILE caption("BSC\'s with parameters that are not equal to reference");
print OUTFILE Tr(th([@pcol]));
foreach my $cat (sort keys %results) {
	foreach my $p (keys %{$results{$cat}{'DIFFERENT'}}) {
		my ($hmi) = @{$params->{'parameter'}->{$p}}{qw/hmi_name/};
		my $rval = undef;
		my %aval = ();
		foreach my $bsc (keys %{$results{$cat}{'DIFFERENT'}{$p}}) {
			my ($rf,$ac) = split(';',$results{$cat}{'DIFFERENT'}{$p}{$bsc});
			#$rval = $rf;
			#$aval{$ac}++;
			print OUTFILE Tr(td([$cat,$p,$hmi,$bsc,$rf,$ac]));
		}
		#my $blist = join(',',keys %{$results{$cat}{'DIFFERENT'}{$p}});
		#my $alist = join(',',keys %aval);
		#print OUTFILE Tr(td([$cat,$p,$hmi,$blist,$rval,$alist]));
	}
}

print OUTFILE end_table(),"<BR><BR>\n";
print OUTFILE end_html();
close OUTFILE;
copy($fileName,'/var/www/html/confsheets/'.$fileName);
#open(OUT,'>output/csv/parameterComparison.CSV') || die "Cannot open outfile : $!\n";
#open(NOCHECK,'>NOT-CHECKED.csv') || die "Cannot open outfile : $!\n";
#print OUT 'CATEGORY;OMC-R HMI NAME;ACIE PARAMETER NAME;DIFFERENCE;'.join(';',@name)."\n";
#print NOCHECK "CATEGORY;OMC-R HMI NAME\n";


#close(OUT);
#close(NOCHECK);

__END__