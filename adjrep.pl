#!/usr/bin/perl -w

use strict;
use warnings;

use constant VERBOSE		=> 1;
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
use constant TABLE_WIDTH		=> 780;
use constant CELL_NAME_SIZE		=> 18;

use CGI qw(-no_debug :standard :html3 *table);
require "loadACIEsubs.pl";

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

my $EarthRadiusKm = 6371;
my $pi = 3.14159265358979;
my $MaxDistKm = 70;
my $TimeNow = scalar(localtime);

my $GeoData = "/users/hartmut/perls/confscript/Complete_Network_CellPositions.csv";
my $Outfile = "/users/hartmut/perls/confscript/AdjReport.html";


my %BSC = ();
my %CI = ();
my %CellRef = ();
my %Adj = ();
my %Site = ();
my %Shown = ();
my %LatLon = ();


main();
exit;

sub main {
	load_acie();
	load_dist();
	print_reports();
}


sub load_acie {
	my %bsc = map {$_ => 1} qw/RnlAlcatelBSCInstanceIdentifier UserLabel/;
	my %cel = map {$_ => 1} qw/CellInstanceIdentifier CellGlobalIdentity UserLabel RnlSupportingSector BCCHFrequency BsIdentityCode FrequencyRange/;
	my %ext = map {$_ => 1} qw/ExternalOmcCellInstanceIdentifier CellGlobalIdentity/;
	my %adj = map {$_ => 1}	qw/AdjacencyInstanceIdentifier AdjacencyType/;
	loadACIE('Cell','rnl',\%cel);
	loadACIE('ExternalOmcCell','rnl',\%ext);
	loadACIE('Adjacency','rnl',\%adj);
	loadACIE('RnlAlcatelBSC','rnl',\%bsc);
#	
	foreach my $omc (keys %cel) {
		foreach my $cid (keys %{$cel{$omc}}) {
			my ($lac,$ci) = ($cel{$omc}{$cid}{'CellGlobalIdentity'} =~ /.+lac\s(\d+).+ci\s(\d+)/);
			my ($ncc,$bcc) = ($cel{$omc}{$cid}{'BsIdentityCode'} =~ /.+ncc\s(\d+).+bcc\s(\d+)/);
			my $bsic = $ncc*8+$bcc;
			my ($bsc,$bts,$sector) = ($cel{$omc}{$cid}{'RnlSupportingSector'} =~ /.+bsc\s(\d+).+btsRdn\s(\d+).+sectorRdn\s(\d+).+/);
			$CI{$lac.','.$ci} = [$omc,$cid,$cel{$omc}{$cid}{'UserLabel'},$bsc{$omc}{$bsc}{'UserLabel'},$bts,$sector,$cel{$omc}{$cid}{'BCCHFrequency'},$bsic,$cel{$omc}{$cid}{'FrequencyRange'}];
			$CellRef{$cid} = ["$lac,$ci",$bsc{$omc}{$bsc}{'UserLabel'},$cel{$omc}{$cid}{'UserLabel'},$ci];
			$Site{"$omc,$bsc,$bts"}{$sector} = "$lac,$ci";
			
		}
	}
	
	foreach my $omc (keys %ext) {
		foreach my $eid (keys %{$ext{$omc}}) {
			my ($lac,$ci) = ($ext{$omc}{$eid}{'CellGlobalIdentity'} =~ /.+lac\s(\d+).+ci\s(\d+)/);
			$CellRef{$eid} = ["$lac,$ci", "external", "external",$ci];
		}
	}
	
	foreach my $omc (keys %adj) {
		foreach my $aid (keys %{$adj{$omc}}) {
			
			my ($scid,$tcid) = ($aid =~ /cell\s(\{.+\}).+targetCell\s(\{.+?\})/);
			my $cid1 = $CellRef{$scid}->[0];
			my $cid2 = $CellRef{$tcid}->[0];
			
			$Adj{$cid1}{$cid2} =$adj{$omc}{$aid}{'AdjacencyType'};
		}
	}
}



sub load_dist {
	my %fheaders = ();
	my $i = 0;
	if (-e $GeoData && -s $GeoData) {
		print "Found GeoData ..loading it\n";
		open INFILE, $GeoData or die("Cannot open $GeoData :$!");
		my $line = <INFILE>;
		chomp $line;
		for (split (',', $line)) {
			s/\s//g;	# kill whitespaces
			$fheaders{$_} = $i++;
		}
		if (!(exists $fheaders{'CI'}) || !(exists $fheaders{'LAC'}) || !(exists $fheaders{'LAT'}) || !(exists $fheaders{'LON'}) ) {
			close INFILE;
			die("The file $GeoData does not contain the correct headers (LAC CI LAT LON)");
		}
		while ($line = <INFILE>) {
			chomp ($line);
			my @vals = split (',', $line);
			$LatLon{$vals[$fheaders{'LAC'}].','.$vals[$fheaders{'CI'}]} = [ $vals[$fheaders{'LAT'}], $vals[$fheaders{'LON'}] ];
		}
		close INFILE;
	}
}

sub print_reports {
	print "Generating report ..(this may need some time to complete)\n";
	open OUTFILE, ">$Outfile" or die "Cannot open $Outfile for writing: $!\n";
	print OUTFILE start_html(	-title=>'AdjReport',
					-author=>'hartmut.behrens@alcatel-lucent.co.za',
					-age=>'0',
					-meta=>{'http-equiv'=>'no-cache',
							'copyright'=>'H. Behrens @ Alcatel-Lucent'},
					-BGCOLOR=>(CLR_BG),
					-style=>{-code=>"$style"}
					);
	print OUTFILE h3("Adjacency Report V1.2");
	print OUTFILE p("Last Run Time: $TimeNow on host: ".`"hostname"`);

	
	# Same BCCH amongst neighbours ...
	%Shown = ();
	print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print OUTFILE caption("Same BCCH used amongst neighbours"), "\n";;
	print OUTFILE Tr(th({-colspan=>5},"Source"),th({-colspan=>5},"Target") ),"\n";
	print OUTFILE Tr(th(["BSC", "CI", "Cell Name", "BCCH", "BSIC" ,"BSC", "CI", "Cell Name", "BCCH", "BSIC"])),"\n";
	for my $ci1 (keys %Adj) {
		for my $ci2 (keys %{$Adj{$ci1}}) {
		       
			if ((exists $CI{$ci1}) && (exists $CI{$ci2}) && ($CI{$ci1}->[6] eq $CI{$ci2}->[6]) && (!exists ($Shown{$ci1}{$ci2}))&& (!exists ($Shown{$ci2}{$ci1}))) {
			        #print "BCCH1 : ",$CI{$ci1}->[6]," BCCH2 : ",$CI{$ci2}->[6],"\n";
				#$CI{$cci} = [$omc, $cref, $cname, $BSC{$1}, $2, $3, $_->[4], $bsic, $lac];
				print OUTFILE Tr(td([	$CI{$ci1}->[3], $ci1, $CI{$ci1}->[2], $CI{$ci1}->[6], $CI{$ci1}->[7],
										$CI{$ci2}->[3], $ci2, $CI{$ci2}->[2], $CI{$ci2}->[6], $CI{$ci2}->[7]
									])),"\n";
				$Shown{$ci1}{$ci2}++;

			}
		}
	}
	print OUTFILE end_table(), "\n<br><br>";
	#exit;


	# Same BCCH+BSIC amongst SO neighbours ...
	%Shown = ();
	print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print OUTFILE caption("Same BCCH and BSIC used in the same vicinity (determined by Second-Order Neighbours)"), "\n";;
	print OUTFILE Tr(th({-colspan=>5},"Source Cell"),th({-colspan=>5},"Second-Order Neighbour") ),"\n";
	print OUTFILE Tr(th(["BSC", "CI", "Cell Name", "BCCH", "BSIC" ,"BSC", "CI", "Cell Name", "BCCH", "BSIC"])),"\n";
	for my $ci1 (keys %Adj) {
		for my $ci2 (keys %{$Adj{$ci1}}) {
			for my $ci3 (keys %{$Adj{$ci2}}) {
				next if ($ci3 eq $ci1);
				next if (exists $Adj{$ci1}{$ci3});	# FO neighbour
					if ((exists $CI{$ci1}) && (exists $CI{$ci3}) && ($CI{$ci1}->[6] eq $CI{$ci3}->[6]) && ($CI{$ci1}->[7] eq $CI{$ci3}->[7]) && (!exists ($Shown{$ci1}{$ci3}))&& (!exists ($Shown{$ci3}{$ci1}))) {
						#$CI{$cci} = [$omc, $cref, $cname, $BSC{$1}, $2, $3, $_->[4], $bsic, $lac];
						print OUTFILE Tr(td([	$CI{$ci1}->[3], $ci1, $CI{$ci1}->[2], $CI{$ci1}->[6], $CI{$ci1}->[7],
												$CI{$ci3}->[3], $ci3, $CI{$ci3}->[2], $CI{$ci3}->[6], $CI{$ci3}->[7]
											])),"\n";
						$Shown{$ci1}{$ci3}++;
		
					}
			}
		}
	}
	print OUTFILE end_table(), "\n<br><br>";

	# handovers out of TA
	%Shown = ();
	if (scalar keys %LatLon) {	# have distance info
		print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
		print OUTFILE caption("Handovers defined between cells spaced more than $MaxDistKm"."km apart (pure reselections are excluded)"), "\n";;
		print OUTFILE Tr(th({-colspan=>3},"Source"),th({-colspan=>3},"Target"), th("Distance") ),"\n";
		print OUTFILE Tr(th(["BSC", "CI", "Cell Name","BSC", "CI", "Cell Name", "km"])),"\n";
		for my $ci1 (keys %Adj) {
			for my $ci2 (keys %{$Adj{$ci1}}) {
				next if (exists ($Shown{$ci1}{$ci2}) || exists ($Shown{$ci2}{$ci1}));
				if ( (exists $LatLon{$ci1}) && (exists $LatLon{$ci2}) && 
					 (defined $LatLon{$ci1}->[0]) && (defined $LatLon{$ci1}->[1]) &&
					 (defined $LatLon{$ci2}->[0]) && (defined $LatLon{$ci2}->[1]) &&
					 ($LatLon{$ci1}->[0] =~ /\d+/) && ($LatLon{$ci1}->[1] =~ /\d+/) &&
					 ($LatLon{$ci2}->[0] =~ /\d+/) && ($LatLon{$ci2}->[1] =~ /\d+/)
					) {
					my $km = haversine(d2r($LatLon{$ci1}->[0]),d2r($LatLon{$ci1}->[1]),d2r($LatLon{$ci2}->[0]),d2r($LatLon{$ci2}->[1]));
					if (($km > $MaxDistKm) && ($Adj{$ci1}->{$ci2} =~ /handover/i)){
						print OUTFILE Tr(td([$CI{$ci1}->[3], $ci1, $CI{$ci1}->[2],$CI{$ci2}->[3], $ci2, $CI{$ci2}->[2], sprintf("%0.2f",$km)])),"\n";
					}
					$Shown{$ci1}{$ci2}++;
				}
			}
		}
		print OUTFILE end_table(), "\n<br><br>";
	}

	# missing sector handovers...
	%Shown = ();
	print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print OUTFILE caption("Missing H/O between sectors (using same rack!)"), "\n";;
	print OUTFILE Tr(th({-colspan=>3},"Source"),th({-colspan=>3},"Target") ),"\n";
	print OUTFILE Tr(th(["BSC", "CI", "Cell Name","BSC", "CI", "Cell Name"])),"\n";
	for my $site (keys %Site) {
		my @sectors = ();
		for my $sector (keys %{$Site{$site}}) {
			push @sectors, $Site{$site}{$sector};
		}
		for my $sector (@sectors) {
			for my $ix (0..$#sectors) {
				if ($sector ne $sectors[$ix]) {
					my $ci1 = $sector;
					my $ci2 = $sectors[$ix];
					if (!exists $Adj{$ci1}{$ci2}) {
						print OUTFILE Tr(td([$CI{$ci1}->[3], $ci1, $CI{$ci1}->[2],$CI{$ci2}->[3], $ci2, $CI{$ci2}->[2]])),"\n";
						$Shown{$ci1}{$ci2}++;
					}
				}
			}
		}
	}
	print OUTFILE end_table(), "\n<br><br>";

	# possibles based on name ...
	print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print OUTFILE caption("Possible missing H/O based on cell name recognition (may catch some missing H/O between bands)"), "\n";;
	print OUTFILE Tr(th({-colspan=>3},"Source"),th({-colspan=>3},"Target") ),"\n";
	print OUTFILE Tr(th(["BSC", "CI", "Cell Name","BSC", "CI", "Cell Name"])),"\n";
	for my $ci1 (keys %CI) {
		for my $ci2 (keys %CI) {
			if ($ci1 ne $ci2) {
				# simplify cell names
				my ($name1, $name2) = ($CI{$ci1}->[2], $CI{$ci2}->[2]);
				next if ((!defined $name1) || (!defined $name2) || ($name1 !~ /\w+/) || ($name2 !~ /\w+/));
				$name1 =~ s/\d+$//;	# remove sector number (digit at end of name)
				$name1 =~ s/_S_//;
				$name1 =~ s/_S$//;
				#$name1 =~ s/_N_//;
				#$name1 =~ s/_N$//;
				$name1 =~ s/DCS//;
				$name1 =~ s/GSM//;
				$name1 =~ s/_//g;
				$name1 =~ s/\-//g;
			
				$name2 =~ s/\d+$//;	#
				$name2 =~ s/_S_//;
				$name2 =~ s/_S$//;
				#$name2 =~ s/_N_//;
				#$name2 =~ s/_N$//;
				$name2 =~ s/DCS//;
				$name2 =~ s/GSM//;
				$name2 =~ s/_//g;
				$name2 =~ s/\-//g;

				if (($name1 eq $name2) && (!exists ($Adj{$ci1}{$ci2})) && (!exists ($Shown{$ci1}{$ci2}))) {
					print OUTFILE Tr(td([$CI{$ci1}->[3], $ci1, $CI{$ci1}->[2],$CI{$ci2}->[3], $ci2, $CI{$ci2}->[2]])),"\n";
				}
			}
		}
	}
	print OUTFILE end_table(), "\n<br><br>";

	# one-way handovers...
	print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print OUTFILE caption("Handovers defined in only one direction (extended cells in restriction)"), "\n";;
	print OUTFILE Tr(th({-colspan=>6},"Source"),th("HO"),th({-colspan=>6},"Target") ),"\n";
	print OUTFILE Tr(th(["OMC", "BSC", "CI", "Cell Name", "BCCH", "BSIC"," ", "OMC", "BSC", "CI", "Cell Name", "BCCH", "BSIC"])),"\n";
	for my $ci1 (keys %Adj) {
		for my $ci2 (keys %{$Adj{$ci1}}) {
			if ( !(exists $Adj{$ci2}{$ci1})  && (exists ($CI{$ci2})) &&  !(exists ($Shown{$ci1}{$ci2})) ) {
				
				print OUTFILE Tr(td([	$CI{$ci1}->[0], $CI{$ci1}->[3], $ci1, $CI{$ci1}->[2], $CI{$ci1}->[6], $CI{$ci1}->[7], ">>>",
										$CI{$ci2}->[0], $CI{$ci2}->[3], $ci2, $CI{$ci2}->[2], $CI{$ci2}->[6], $CI{$ci2}->[7]])),"\n";
				$Shown{$ci1}{$ci2}++;
			}
		}
	}
	print OUTFILE end_table(), "\n<br><br>";
	
	# Wrong Handove/Reselection flags
	print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print OUTFILE caption("Adjacencies in the P-GSM frequency band that are other than 'Handover AND Reselection'"), "\n";;
	print OUTFILE Tr(th({-colspan=>5},"Source Cell"),th("Adjacency Type"),th({-colspan=>5},"Target Cell") ),"\n";
	print OUTFILE Tr(th(["BSC", "CI", "Cell Name", "BCCH", "BSIC" , "", "BSC", "CI", "Cell Name", "BCCH", "BSIC"])),"\n";

	for my $ci1 (keys %Adj) {
		for my $ci2 (keys %{$Adj{$ci1}}) {
			next unless exists $CI{$ci2};		#weed out dummy neighbours
			if (($Adj{$ci1}{$ci2} !~ /handoverandreselection/i) && ($CI{$ci1}->[8] eq $CI{$ci2}->[8]) && ($CI{$ci1}->[8] =~ /p\-gsm/i) ) {
				
				print OUTFILE Tr(td([	$CI{$ci1}->[3], $ci1, $CI{$ci1}->[2], $CI{$ci1}->[6], $CI{$ci1}->[7],
										$Adj{$ci1}{$ci2},
										$CI{$ci2}->[3], $ci2, $CI{$ci2}->[2], $CI{$ci2}->[6], $CI{$ci2}->[7]
									])),"\n";

			}
		}

	}

	print OUTFILE end_table(), "\n<br><br>";
	print OUTFILE end_html();
	
	# repeated CI...
	print OUTFILE start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print OUTFILE caption("Repetition of Cell Identity - only interesting for networks prior to B9"), "\n";;
	print OUTFILE Tr(th(""),th({-colspan=>3},"Instance 1"),th({-colspan=>3},"Instance 2") ),"\n";
	print OUTFILE Tr(th(["Repeated CI", "OMC,Cellref", "BSC","Cell Name", "OMC,Cellref", "BSC", "Cellname"])),"\n";
	for my $cr1 (keys %CellRef) {
		for my $cr2 (keys %CellRef) {
			next if ($cr1 eq $cr2);
			if (($CellRef{$cr1}->[3] eq $CellRef{$cr2}->[3]) && ($CellRef{$cr1}->[1] ne 'external') && ($CellRef{$cr2}->[1] ne 'external')){
				print OUTFILE Tr(td([$CellRef{$cr1}->[3],$cr1,$CellRef{$cr1}->[1],$CellRef{$cr1}->[2],$cr2,$CellRef{$cr2}->[1],$CellRef{$cr2}->[2]   ])),"\n";
			}
		}
	}
	print OUTFILE end_table(), "\n<br><br>";
	close OUTFILE;
}



sub haversine { # haversine eliminates error of very small numbers (does it matter though?)
	my ($lat1, $lon1, $lat2, $lon2) = @_;
	my $a = (sin(($lat2 - $lat1)/2))**2 + cos($lat1) * cos($lat2) * (sin(($lon2 - $lon1)/2))**2;
	return ($EarthRadiusKm * 2 * atan2( sqrt($a), sqrt(1-$a) ) );
}

sub d2r {
	my ($deg) = @_;
	return ( ($deg*$pi) / 180 );
}

sub r2d {
	my ($rad) = @_;
	return ( ($rad*180) / $pi );
}

__END__
