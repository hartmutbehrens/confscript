#!/usr/bin/perl -w
#2005, Hartmut Behrens
#hartmut.behrens@alcatel.co.za
#enumerate the difference between two ACIE exports
use strict;
use warnings;

require "subs.pl";
require "loadACIEsubs.pl";

#load config
my $confFile = "etc/conf.ini";
my ($aref,$href) = read_conf($confFile);
my @acie = qw/Adjacency Cell RnlAlcatelBSC SubNetwork RnlAlcatelSiteManager RnlAlcatelSector RnlAlcatelMFS RnlPowerControl RnlFrequencyHoppingSystem/;
my $dbh = undef;
my %oldA = ();
my %newA = ();
require "/var/tools/radar/bin/subs/CommonSubs.pl";
connect_db(\$dbh) or die("Cannot open DB\n");	
print "START: Diffing old rnl against current rnl\n";
foreach my $acie (@acie) {
	loadACIE($acie,"rnl",\%newA);
	loadACIE($acie,"oldrnl",\%oldA);
	checkAcie(\%oldA,\%newA,$acie);
	%oldA = ();
	%newA = ();
}
print "END: Diffing old rnl against current rnl\n";
exit;

sub checkAcie {
	my ($oldR,$newR,$acie) = @_;
	my %change = ();
	my $date = ();
	print "Processing old $acie\n";
	foreach my $omc (keys %{$oldR}) {
		foreach my $id (keys %{$oldR->{$omc}}) {
			if (not exists($newR->{$omc}->{$id})) {
				my $k = join(',',keys %{$oldR->{$omc}->{$id}});
				my $v = join(',',values %{$oldR->{$omc}->{$id}});
				$k =~ s/\'/\\\'/g;
				$v =~ s/\'/\\\'/g;
				my $sql = "replace into M_AcieChange values (\'$acie\','DELETED_ELEMENT',$omc,\'$date\',\'$id\',\'\',\'$k\',\'$v\')";
				$dbh->do($sql) or die "$dbh->errstr\n";
				next;
			}
			$date = $newR->{$omc}->{$id}->{'IMPORTDATE'};
			#see if param's have been added/deleted/changed
			my ($a,$d,$c) = getDiff($oldR->{$omc}->{$id},$newR->{$omc}->{$id});
			my @addVals = @{$newR->{$omc}->{$id}}{@{$a}};
			my @delVals = @{$oldR->{$omc}->{$id}}{@{$d}};
			
			if (@{$a}) {
				foreach my $col (@{$a}) {
					my $sql = "replace into M_AcieChange values (\'$acie\','NEW_PARAM_ADDED',$omc,\'$date\',\'$id\',\'$col\',\'$newR->{$omc}->{$id}->{$col}\',\'$newR->{$omc}->{$id}->{$col}\')";
					$dbh->do($sql) or die "$dbh->errstr\n";
				}
			}
			if (@{$d}) {
				foreach my $col (@{$d}) {
					my $sql = "replace into M_AcieChange values (\'$acie\','PARAM_REMOVED',$omc,\'$date\',\'$id\',\'$col\',\'$oldR->{$omc}->{$id}->{$col}\',\'$oldR->{$omc}->{$id}->{$col}\')";
					$dbh->do($sql) or die "$dbh->errstr\n";
				}
			}
			if (@{$c}) {
				foreach my $col (@{$c}) {
					my $oldVal = $oldR->{$omc}->{$id}->{$col};
					my $newVal = $newR->{$omc}->{$id}->{$col};
					$oldVal =~ s/\'/\\\'/g;
					$newVal =~ s/\'/\\\'/g;
					my $sql = "replace into M_AcieChange values (\'$acie\','VAL_CHANGE',$omc,\'$date\',\'$id\',\'$col\',\'$oldVal\',\'$newVal\')";
					$dbh->do($sql) or die "$dbh->errstr\n";
				}
			}
			delete $newR->{$omc}->{$id};
		}
	}
	print "Processing new $acie\n";
	foreach my $omcn (keys %{$newR}) {
		foreach my $idn (keys %{$newR->{$omcn}}) {
			if (not (exists($oldR->{$omcn}->{$idn})) ) {
				my $sql = "replace into M_AcieChange values (\'$acie\','ADDED_ELEMENT',$omcn,\'$date\',\'$idn\',\'\',\'\',\'\')";
				$dbh->do($sql) or die "$dbh->errstr\n";
			}
		}
	}
}

#get difference of two hashes
sub getDiff {
	my ($a,$b) = @_;
	delete $a->{'IMPORTDATE'};
	delete $b->{'IMPORTDATE'};
	delete $a->{'OMC_VERSION'};
	delete $b->{'OMC_VERSION'};
	delete $a->{'RnlAdjWhereTarget'} if exists($a->{'RnlAdjWhereTarget'});
	delete $b->{'RnlAdjWhereTarget'} if exists($b->{'RnlAdjWhereTarget'});
	my @add = ();	my @del = ();	my @chang = ();
	my %count = ();
	foreach my $e (keys %{$a}, keys %{$b}) { $count{$e}++ }

	foreach my $e (keys %count) {
    if ($count{$e} == 2 ) {
    	#print "$e\n";
    	push(@chang,$e) if (($a->{$e} || '') ne ($b->{$e} || ''));				# || '' is for non-populated vals in ACIE
    }
    else {
    	push @{ defined($b->{$e}) ? \@add : \@del }, $e;
    }
	}
	return(\@add,\@del,\@chang);
}


__END__