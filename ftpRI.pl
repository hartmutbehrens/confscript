#!/usr/bin/perl -w
#!c:/Perl/bin/Perl.exe -w

# 2009 by Hartmut Behrens (##)
# copy Remote Inventory files from OMC's defined in conf.ini..

# perl settings part
use warnings;
use strict;
use Net::FTP;
use File::Path;
use Data::Dumper;

# load .ini configuration,general variables setup
require "subs.pl";
my $get_dir = 'data/ri/';
my ($aref,$href) = read_conf("etc/conf.ini");

mkpath($get_dir, {verbose => 1}) unless (-e $get_dir);
foreach my $omc (@{$aref}) {
	print "Processing ",$href->{'OMC'.$omc.'_Hostname'},"..\n";
	my $ftp = Net::FTP->new($href->{'OMC'.$omc.'_IP'}, Debug => 0) || die "Could not establish an FTP connection to ",$href->{'OMC'.$omc.'_IP'}," !\n";
	$ftp->login($href->{'OMC'.$omc.'_USERNAME'},$href->{'OMC'.$omc.'_PASSWORD'});
	
	for (qw(abtrie amerie absrie)) {
		my $file = $href->{'OMC'.$omc.'_RA1353RAInstance'}.'_'.$_.'.csv';
		$ftp->get($href->{'OMC'.$omc.'_ARIEDIR'}.$file,$get_dir.$file);	
	}
	$ftp->quit;
}

print "\n__Done__\n";

__END__
