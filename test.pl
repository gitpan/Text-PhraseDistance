use strict;
use Text::PhraseDistance qw(pdistance);

sub distance {

	# Hamming distance
	#
	# By Leo Cacciari aka TheHobbit, <thehobbit at altern.org>
	#
	# Copyright (c) 2002 Leo Cacciari. All rights reserved.  This subroutine is
	# free software; you can redistribute it and/or modify it under the same
	# terms as Perl itself

	my ($x,$y) = @_;

	my $result = abs (length($x) - length($y));
	my $len = (length($x) < length($y)) ? length($x) : length($y);

	$x = substr($x,0,$len);
	$y = substr($y,0,$len);

	foreach my $i (0..$len-1) {
		$result++ if substr($x,$i,1) ne substr($y,$i,1);
	}

	return $result;
}


my $phrase1="a yellow dog";
my $phrase2="a cat,yellow";
my $set="abcdefghijklmnopqrstuvwxyz";

print "The distance: ".pdistance($phrase1,$phrase2,$set,\&distance)." should be 6\n";
print "The distance: ".pdistance($phrase1,$phrase2,$set,\&distance,{-mode=>'both'})." should be 6\n";
print "The distance: ".pdistance($phrase1,$phrase2,$set,\&distance,{-mode=>'complementary'})." should be 1\n";
print "The distance: ".pdistance($phrase1,$phrase2,$set,\&distance,{-mode=>'set'})." should be 5\n";
print "The distance: ".pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[0.5,1]})." should be 4\n";
print "The distance: ".pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[0.5,1],-mode=>'both'})." should be 4\n";
print "The distance: ".pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[0.5,1],-mode=>'set'})." should be 3.5\n";
print "The distance: ".pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[0.5,1],-mode=>'complementary'})." should be 0.5\n";

