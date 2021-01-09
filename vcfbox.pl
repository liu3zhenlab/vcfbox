#!/use/bin/perl -w
#
# Author: Sanzhen Liu <liu3zhen@ksu.edu>
# 7/21/2019
#
use strict;
use warnings;
use Getopt::Std;


sub usage {
	die(qq/
		Usage: $0 <module> [arguments]\n
		Modules: vcf2std        : convert vcf to a standard table
		std2carthagene : convert std to CarthaGene geno
	\n/);
}


&master;
exit;
sub master {
	&usage if (@ARGV < 1);
	my $cmd = shift(@ARGV);
	my %modules = (vcf2std=>\&vcf2std,
                   std2carthagene=>\&std2carthagene
				   ); # to add more
	die ("Unknown module \"$cmd\".\n") if (!defined ($modules{$cmd}));
	&{$modules{$cmd}};
}


sub vcf2std {
	my %opts = (r=>1, a=>2, h=>3, m=>0);
	getopts('r:a:h:m:', \%opts);
	my $refhomo = $opts{r};
	my $althomo = $opts{a};
	my $hetero = $opts{h};
	my $missing = $opts{m};

	my %genocode = ("0/0" => $refhomo, "0|0" => $refhomo, "0" => $refhomo,
	                "1/1" => $althomo, "1|1" => $althomo, "1" => $althomo,
					"0/1" => $hetero, "0|1" => $hetero,
					"1/0" => $hetero, "1|0" => $hetero,
					"./." => $missing, ".|." => $missing, "." => $missing);

	die(qq/
Usage: $0 vcf2std [options] <vcf> 
{arguments]
  -r: code for homozygous genotypes of ref alleles; default=1
  -a: code for homozygous genotypes of alt alleles; default=2
  -h: code for heterozygous genotypes; default=3
  -m: code for missing data; default=0
[note]: this script only works for biallele vcf results.
\n/) if (@ARGV==0 && -t STDIN);

	while(<>) {
		if (! /^\#\#/) {
			my @line = split;
			if (/^\#/) {
				$line[0] =~ s/^\#//;
				print join("\t", @line[0,1,3,4,9..$#line]);
				print "\n";
			} else {
				print join("\t", @line[0,1,3,4]);
				
				for (my $i=9; $i<=$#line; $i++) {
					my $geno = $line[$i];
					$geno =~ s/\:.*//g;
					if (exists $genocode{$geno}) {
						print "\t$genocode{$geno}";
					} else {
						print STDERR "ERROR: $geno is NOT a standard genotype format.\n";
						exit;
					}
				}
				
				print "\n";
			}
		}
	}
}


# module: std2carthagene
sub std2carthagene {	
	my %opts = (p=>"ri self", r=>1, a=>2, h=>3, m=>0);
	getopts('p:r:a:h:m:', \%opts);
	my $poptype = $opts{p};
	
	my $refhomo = $opts{r};
	my $althomo = $opts{a};
	my $hetero = $opts{h};
	my $missing = $opts{m};
	
	my %genocode;
	$genocode{$refhomo} = 1;
	$genocode{$althomo} = 8;
	$genocode{$hetero} = 6;
	$genocode{$missing} = "f";

	die(qq/
Usage: genoformat.pl std2carthagene [options] <std> 
{arguments]
	-p: population type ("f2", "ri self")
	-r: original code for homozygous genotypes of ref alleles; default=1
	-a: original code for homozygous genotypes of alt alleles; default=2
	-h: original code for heterozygous genotypes; default=3
	-m: original code for missing data; default=0
\n/) if (@ARGV==0 && -t STDIN);
	
	my $ninds = 0;
	my $nmarkers = undef;
	my %markers;
	while(<>) {
		chomp;
		my @line = split;
		if (!defined $nmarkers) {
			$ninds = $#line - 3;
			$nmarkers = 0;
		} else {
			my $marker = join("_", @line[0..3]);
			$nmarkers++;
			my $genostrings = "";
			
			# concatenate all genos:
			for (my $i=4; $i<=$#line; $i++) {
				my $newcode;
				if (exists $genocode{$line[$i]}) {
					$newcode = $genocode{$line[$i]};
				} else {
					print STDERR "ERROR: genotype code $line[$i] was not recognized\n";
					exit;
				}
				
				$genostrings .= $newcode;
			}
			# add geno info to a hash:
			$markers{$marker} = $genostrings;
		}
	}

	# output
	print "data type $poptype\n";
	print "$ninds $nmarkers 0 0 1=A 6=H 8=B f=-\n";
	foreach my $em (keys %markers) {
		print "\*$em $markers{$em}\n";
	}
}




sub usage {
	die(qq/
Usage: $0 <module> [arguments]\n
Modules: vcf2std		: convert vcf to a standard table
         std2carthagene	: convert std to CarthaGene geno
		 
\n/);
}

