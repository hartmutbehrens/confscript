#!/usr/bin/perl -w
#!c:/Perl/bin/Perl.exe -w

# 2007 by Hartmut Behrens (##)
# copy rnl,eml,ml files

# perl settings part
use warnings;
use strict;
use Net::FTP;
use Getopt::Std;
use Time::Local;

use constant THRESHOLD => 259200;


# load .ini configuration,general variables setup
my %args;
require "subs.pl";
my ($aref,$href) = read_conf("etc/conf.ini");
my @filetypes = qw(rnl eml ml);
my %dir = ('rnl' => 'data/rnl/',
					 'eml' => 'data/eml/',
					 'ml'	=> 'data/ml/');
					 					 
my %load = ('rnl' => 'NlSCExport.tgz',
					 'eml' => 'BlExport.tgz',
					 'ml'	=> 'MlExport.tgz');
					 
my %remote = ('rnl' => 'ACIE_NLexport_Dir1/',
					 		'eml' => 'ACIE_BLexport/',
					 		'ml'	=> 'ACIE_MLexport/');
					 		
my %recurse = ('rnl' => 'no',
							 'eml' => 'Dir1',
							 'ml'  => 'Dir1',);

for (@filetypes) {
	mkdir($dir{$_}) unless (-e $dir{$_});
}

#Find out which files to copy
getopt("fl",\%args);
die "Specify file type to copy with : -f [",join('|',@filetypes),"]\n" unless defined ($args{f});
die "Specified file type is invalid !\n" unless (grep {/$args{f}/i} @filetypes);


print "FTPing $args{f} files...\n";
ftpFiles(lc($args{'f'}));


print "\n__Done__\n";
##subroutines from here

sub ftpFiles {
	my ($which) = @_;
	my $prefix = '';
	my ($now) = timelocal(localtime);
	unlink <$dir{$which}*.*> unless exists $args{'l'};
	foreach my $omc (@{$aref}) {
		if (exists $args{'l'}) {
			if (exists $href->{'OMC'.$omc.'_LABOMC'}) {
				$prefix = 'lab_' if (lc($href->{'OMC'.$omc.'_LABOMC'}) eq 'true');
			}
			else {
				next;
			}
		}
		else {
			if (exists $href->{'OMC'.$omc.'_LABOMC'}) {
				next if (lc($href->{'OMC'.$omc.'_LABOMC'}) eq 'true');
			}
		}
		
		print "\tFTP from ",$href->{'OMC'.$omc.'_Hostname'},"...\n";
		my $rdir = $href->{'OMC'.$omc.'_ACIEDIR'}.$remote{$which};
		my $ftp = Net::FTP->new($href->{'OMC'.$omc.'_IP'}, Debug => 0);
		$ftp->login($href->{'OMC'.$omc.'_USERNAME'},$href->{'OMC'.$omc.'_PASSWORD'});
		$ftp->type('I');
		$ftp->cwd($rdir);
		if ($recurse{$which} eq 'no') {
			my ($tm) = $ftp->mdtm($rdir.$load{$which});
			my $diff = $now - $tm;
			if ($diff > THRESHOLD) {
				print "\n$rdir contains old data, and will not be copied !\n";
				next;
			}
			
			$ftp->get($rdir.$load{$which},$dir{$which}.$prefix.$omc.$load{$which});
			print "done\n";
		}
		else {
			my @dirs = grep {/$recurse{$which}$/} $ftp->ls($rdir);
			foreach my $d (@dirs) {
				my ($id) = ($d =~ /.*?(\d+)export.*?/);
				my ($tm) = $ftp->mdtm($d.'/'.$load{$which});
				print "ID is $id, tm is $tm\n";
				next unless defined($tm);
				my $diff = $now - $tm;
				#print "$diff : $now : $tm \n";
				if ($diff > THRESHOLD) {
					print "\n$d contains old data, and will not be copied !\n";
					next;
				}
				$ftp->get($d.'/'.$load{$which},$dir{$which}.$prefix.$omc.'_'.$id.'_'.$load{$which});
				print "*";
			}
		}
		$ftp->quit;
	}
}

__END__
