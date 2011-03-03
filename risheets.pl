#!/usr/bin/perl -w

use strict;
use warnings;
use Carp;
use CGI qw(-no_debug :standard :html3 *table);
use File::Path;
require "loadACIEsubs.pl";
require "subs.pl";

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
				

my $get_dir = 'data/ri/';
my $out_dir = '/var/www/html/risheets/';
if ($^O =~ /mswin/i) {
	$out_dir = 'output/ri/';
}
mkpath($out_dir, {verbose => 1}) unless (-e $out_dir);
unlink <$out_dir*.html>;
unlink <$out_dir*.csv>;
my ($aref,$href) = read_conf("etc/conf.ini");	
				
my %site = (
	"RnlAlcatelSiteManagerInstanceIdentifier"	=>1,
	"BTS_Generation"				=>1,
	"UserLabel"					=>1
	);

my %index;
my %omc = map {$href->{'OMC'.$_.'_RA1353RAInstance'} => $href->{'OMC'.$_.'_Hostname'}} @{$aref};

my %rnlBSC = ("RnlAlcatelBSCInstanceIdentifier"	=>1,"RnlRelatedMFS"=>1,"UserLabel"	=>1);
my %rnlMFS = ("RnlAlcatelMFSInstanceIdentifier"	=>1,"UserLabel"	=>1);
loadACIE("RnlAlcatelBSC","rnl",\%rnlBSC);
loadACIE("RnlAlcatelMFS","rnl",\%rnlMFS);
for my $omc (keys %rnlBSC) {
	my $host = $omc{$omc} || $omc;
	for my $bsc_id (keys %{$rnlBSC{$omc}}) {
		my $mfs = $rnlMFS{$omc}{$rnlBSC{$omc}{$bsc_id}{'RnlRelatedMFS'}}{'UserLabel'} || 'NO_MFS_YET';
		my $bsc = $rnlBSC{$omc}{$bsc_id}{'UserLabel'};
		$bsc =~ s/\"//g;
		$mfs =~ s/\"//g;
		start_file($bsc,'BSC');
		start_file($mfs,'MFS');
		$index{$host}{$mfs}{$bsc} = 1;
	}
}

foreach my $omc (keys %omc) {
	my @bsc_id = ('Equipment Label','RACK','SUBRACK','SLOT');
	my @bts_id = ('EqtLabel','ScanDate','Rack','Shelf','Slot');
	
	my @bsc_data = ('PART NUMBER+ICS','MNEMONIC','SERIAL NUMBER','Network Element Id','SCAN DATE');
	my @bts_data = ('PartNumberAndICS','Mnemonic','SerialNumber','NEId','ScanDate');
	
	my $bsc_ref = group_ri_csv($get_dir.$omc.'_absrie.csv',\@bsc_id,\@bsc_data,$omc{$omc}.'_BSC');
	my $bts_ref = group_ri_csv($get_dir.$omc.'_abtrie.csv',\@bts_id,\@bts_data,$omc{$omc}.'_BTS');
	my $mfs_ref = group_ri_csv($get_dir.$omc.'_amerie.csv',\@bsc_id,\@bsc_data,$omc{$omc}.'_MFS');
	
	
	add_html($bsc_ref,['MNEMONIC','SERIAL NUMBER','PART NUMBER+ICS','SCAN DATE'],'BSC');
	add_bts_html($bts_ref,['Mnemonic','SerialNumber','PartNumberAndICS']);
	add_html($mfs_ref,['MNEMONIC','SERIAL NUMBER','PART NUMBER+ICS','SCAN DATE'],'MFS');
}

make_html_index();

sub start_file {
	my ($element,$which) = @_;
	open my $fh,'>>',$out_dir.$element.'.html' || die "Could not open file $element.html for writing : $!\n";
	print $fh start_html(	-title=>"Remote Invetory Sheet for $which $element",-author=>'hartmut.behrens@alcatel.co.za',-age=>'0',-meta=>{'http-equiv'=>'no-cache'},-BGCOLOR=>(CLR_BG),-style=>{-code=>"$style"});
	close $fh;
}

sub add_html {
	my ($ri_ref,$col_ref,$which) = @_;
	for my $elem (sort keys %$ri_ref) {
		open my $fh,'>>',$out_dir.$elem.'.html' || die "Could not open file $elem.html for writing : $!\n";
		make_ungrouped_html($fh,$ri_ref->{$elem},$col_ref,$which,$elem);
		close $fh;
	}
}

sub add_bts_html {
	my ($bts_ref,$col_ref) = @_;
	my %seen;
	for my $elem (sort keys %$bts_ref) {
		my @dates = reverse sort datesort keys %{$bts_ref->{$elem}};
		my ($bsc,$bts) = ($elem =~ /BSC\s(\w+).*?BTS\s(.*)$/);
		open my $fh,'>>',$out_dir.$bsc.'.html' || die "Could not open file $bsc.html for writing : $!\n";
		make_rss_grouped_html($fh,$bts_ref->{$elem}->{$dates[0]},$col_ref,'BTS',$bts);
	}
}

sub make_rss_grouped_html {
	my ($fh,$rss_ref,$col_ref,$type,$name) = @_;
	my %slots;
	for my $rack (sort {$a <=> $b} keys %$rss_ref) {
		for my $shelf (sort {$a <=> $b} keys %{$rss_ref->{$rack}}) {
			$slots{$_}++ for (keys %{$rss_ref->{$rack}->{$shelf}});
		}
	}
	my @slots = sort {$a <=> $b} keys %slots;
	for my $rack (sort {$a <=> $b} keys %$rss_ref) {
		print $fh "<table><caption>Details</caption><thead>\n";
		
		print $fh "<tr><th>$type</th><td colspan=".scalar(@slots).">$name</td></tr>\n";
		print $fh "<tr><th>Slot</th>".join(' ',map('<th>'.$_.'</th>',@slots))."</tr>\n";
		print $fh "</thead><tbody>\n";
		for my $shelf (sort {$a <=> $b} keys %{$rss_ref->{$rack}}) {	
			print $fh "<tr><th colspan=".(scalar(@slots)+1).">RACK $rack, SHELF $shelf</th></tr>\n";
			
			for my $item (@$col_ref) {
				my @items = map(exists $rss_ref->{$rack}->{$shelf}->{$_} ?  $rss_ref->{$rack}->{$shelf}->{$_}->{$item} : '',@slots);
				print $fh "<tr><th>$item</th>".join(' ',map('<td>'.$_.'</td>',@items))."</tr>\n";
			}
		}
		print $fh "</tbody></table><br>\n";
	}
}

sub make_ungrouped_html {
	my ($fh,$rss_ref,$col_ref,$type,$name) = @_;
	print $fh "<table><caption>Details</caption><thead>\n";
	print $fh "<tr><th>$type</th><td colspan=".(3+scalar(@$col_ref)).">$name</td></tr>\n";
	print $fh "<tr>".join(' ',map('<th>'.$_.'</th>',qw/Rack Shelf Slot/,@$col_ref))."</tr>\n";
	print $fh "</thead><tbody>\n";
	for my $rack ( sort {$a <=> $b} grep {/\d+/} keys %$rss_ref) {
		for my $shelf (sort {$a <=> $b} keys %{$rss_ref->{$rack}}) {	
			for my $slot (sort {$a <=> $b} keys %{$rss_ref->{$rack}->{$shelf}}) {	
				print $fh "<tr>".join(' ',map('<td>'.$_.'</td>',$rack,$shelf,$slot)).join(' ',map('<td>'.$rss_ref->{$rack}->{$shelf}->{$slot}->{$_}.'</td>',@$col_ref))."</tr>\n";
			}
		}
	}
	print $fh "</tbody></table><br>\n";
}




sub make_html_index {
	print "Creating RI Index HTML\n";
	open my $fh, '>', $out_dir.'index.html' or die "Cannot open $out_dir.'ri_index.html for writing! : $!\n";
	print $fh start_html(	-title=>"Remote Inventory Index",-author=>'hartmut.behrens@alcatel-lucent.co.za',-age=>'0',-meta=>{'http-equiv'=>'no-cache'},-BGCOLOR=>(CLR_BG),-style=>{-code=>"$style"});
	print $fh h3("Remote Inventory Index");

	print $fh start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print $fh caption("Remote Inventory"), "\n";
	print $fh Tr(th([sort omcsort keys %index])),"\n";

	print $fh "<TR>";
	print $fh th("MFS/BSC") foreach (keys %index);
	print $fh "</TR>\n";
	my $full = 1;
	my %printed = ();
	while ($full) {
		print $fh "<TR>";
		$full = 0;
		foreach my $omc (sort omcsort keys %index) {
			my @mfs = sort keys %{$index{$omc}};
			if (exists $mfs[0]) {
				my @bsc = sort bscsort keys %{$index{$omc}{$mfs[0]}};
				if (exists($printed{$mfs[0]})) {
					print $fh td(a({href=>"$bsc[0].html"},$bsc[0]));
					delete $index{$omc}{$mfs[0]}{$bsc[0]};
				}
				else {
					print $fh td({-class=>'mfs'},a({href=>"$mfs[0].html"},$mfs[0]));
				}
				$printed{$mfs[0]} = 1;
				delete $index{$omc}{$mfs[0]} unless (keys %{$index{$omc}{$mfs[0]}});
				$full++;
			}
			else {
				print $fh td("");
			}
		}
		print $fh "</TR>\n";
	}
	print $fh end_table(),'<br>';
	
	print $fh start_table({-align=>"CENTER", -border=>0,-width=>(TABLE_WIDTH), -cellpadding=>1, -cellspacing=>1}),"\n";
	print $fh caption("Downloads (Right click mouse on Hyperlink -> Save Target As)"), "\n";
	foreach my $item (qw(BSC BTS MFS) ) {
		print $fh Tr(td([map(a({href=>$_.'_'.$item.'.csv'},"$_ $item RI"),sort omcsort keys %index)])),"\n";
	}
	
	print $fh end_table(),"<BR>\n";
	print $fh end_html();
	close $fh;
}


sub group_ri_csv {
	my ($file,$id_ref,$data_ref,$which) = @_;
	my @cols;
	my %ri; my %d; 
	open my $fh, '<', $file || die "Could not open file $file : $!\n";
	open my $out_fh,'>',$out_dir.$which.'.csv';
	while (<$fh>) {
		chomp;
		next if /ADDIMOD/;
		next if $. < 2;
		if ($. == 2) {
			@cols = split /;|,/;
			print $out_fh join(';',@cols),"\n";
			my %have = map {$_ => 1} @cols;
			my @no_key = grep {$_ ne 'GotIt'} map(exists $have{$_} ? 'GotIt' : $_,@$id_ref);
			my @no_data = grep {$_ ne 'GotIt'} map(exists $have{$_} ? 'GotIt' : $_,@$data_ref);
			confess "The columns @no_key, which were specified as index columns, do not exist in $file !\n" if @no_key;
			confess "The columns @no_data, which were specified as data columns, do not exist in $file !\n" if @no_data;
		}
		else {
			@d{@cols} = split /;|,/;
			my $line = join(';',map(defined $_ ? $_ : '',@d{@cols}));
			$line =~ s/\s//g;
			print $out_fh $line,"\n";
			my $id = join(',',@d{@$id_ref});
			set_hash_value(\%ri,[@d{@$id_ref},$_],$d{$_}) for (@$data_ref);
		}
	}
	close $fh;
	close $out_fh;
	return \%ri;
}

#subroutine that will, given a (hashref, arrayref of keys for the hash, and a value) , set the hashref with value at arbitrary depth
#e.g. if $r{'foo'}{'bar'} = 'foobar' is desired, then use setHashValue(\%r,['foo','bar'],'foobar')
sub set_hash_value {
	my ($href,$aref,$val) = @_;
	
	my $p = \$href;
	$p = \($$p->{$_})	for @{$aref};		#add a key to the hash and then create a ref to the hashref
	$$p = $val;
}

sub datesort {
	my @a = split('\.',$a);
	my @b = split('\.',$b);
	return ($a[2] > $b[2] || $a[1] > $b[1] || $a[0] > $b[0]); 
}

sub bscsort {
	my $bsc_a = substr($a,-4);
	my $bsc_b = substr($b,-4);
	return ($bsc_a cmp $bsc_b);
}

sub omcsort {
	$a =~ /(\d)$/;
	my $omc1 = $1;
	$b =~ /(\d)$/;
	return ($omc1 cmp $1);
}
