use strict;
use Text::PhraseDistance qw(pdistance);

sub distance {

	# Hamming distance
	#
	# By Leo Cacciari aka TheHobbit, <thehobbit at altern.org>
	#
	# Copyright (c) 2002,2003 Leo Cacciari. All rights reserved.  This subroutine is
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
my $phrase3="a big yellow dog";
my $set="abcdefghijklmnopqrstuvwxyz";

my $ko=0;
my $test=1;

if (pdistance($phrase1,$phrase2,$set,\&distance) == 6) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

$test++;
if (pdistance($phrase1,$phrase2,$set,\&distance,{-mode=>'both'}) == 6) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}


$test++;
if (pdistance($phrase1,$phrase2,$set,\&distance,{-mode=>'complementary'}) == 1) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

$test++;
if (pdistance($phrase1,$phrase2,$set,\&distance,{-mode=>'set'}) == 5) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

$test++;
if (pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[0.5,1,0]}) == 4) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

$test++;
if (pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[0.5,1,0],-mode=>'both'}) == 4) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

$test++;
if (pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[0.5,1,0],-mode=>'set'}) == 3.5) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

$test++;
if (pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[0.5,1,0],-mode=>'complementary'}) == 0.5) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

$test++;
if ((pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[1,0,4]}) 
    > pdistance($phrase1,$phrase3,$set,\&distance,{-cost=>[1,0,4]})) 
    &&
    (pdistance($phrase1,$phrase2,$set,\&distance) 
    < pdistance($phrase1,$phrase3,$set,\&distance))) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

if ($ko) {print "\nTest suite failed\n"} else {print "\nTest suite ok\n"}
