package Text::PhraseDistance;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.01';
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&pdistance);
%EXPORT_TAGS = ();

sub _create_sets {

	my ($phrase,$set)=@_;

	$set=quotemeta($set);

	my $RE1 = qr/[$set]/;
	my $RE2 = qr/[^$set]/;

	my @set1 = ();
	my @set2 = ();
	my $flip_flop = 1;

	while ($phrase) {
      	
		if ( $flip_flop ) {
            
			$phrase =~ s/$RE1*//x;
                  	push @set1, $&;
            	}
            	else {

                	$phrase =~ s/$RE2*//x;
                	push @set2, $&;
		}
            
		$flip_flop = !$flip_flop;
	}

	return \@set1,\@set2;
}

sub _set_distance {

	my ($refc,$set1,$set2,$distance)=@_;
	my $string_difference_cost=$$refc[0];
	my $positional_cost=$$refc[1];
	my $dist=-1;

	if ((!scalar @$set1) && (!scalar @$set2)) {

		return 0
	}

	my (%hash,%pset1,%pset2,$state,@states,@min_states,@pset1_states,@pset2_states);

	if ($#$set2 > $#$set1) {my @tmp=@$set2;$set2=$set1;$set1=\@tmp}

	foreach my $iset1 (0..$#$set1) {

		$pset1{$iset1}=1;
		foreach my $iset2 (0..$#$set2) {

			my $dist=&$distance($$set1[$iset1],$$set2[$iset2])*$string_difference_cost
				 +abs($iset1-$iset2)*$positional_cost;
			$hash{"$iset1-$iset2"}=$dist;
		}
		foreach my $iset2 ($#$set2+1 .. $#$set1) {

			$hash{"$iset1-$iset2"}=length($$set1[$iset1])*$string_difference_cost
						+abs($iset1-$iset2)*$positional_cost;
		}
	}
	foreach my $iset2 (0..$#$set2) {$pset2{$iset2}=1;}
	foreach my $iset2 ($#$set2+1 .. $#$set1) {$pset2{$iset2}=1;}

	push @states,\%hash;
	push @min_states,'0';
	push @pset1_states,\%pset1;
	push @pset2_states,\%pset2;

	while (@states) {

		my $min=pop @min_states;
		my $pset1=pop @pset1_states;
		my $pset2=pop @pset2_states;

		my $hash=pop @states;

		my @min;
		my $min_local=-1;

		foreach my $key (sort {$$hash{$a} <=> $$hash{$b}} keys %$hash) {

			if (($$hash{$key} > $min_local) && ($min_local!=-1)) {last}
			$min_local=$$hash{$key};
			push @min,$key;
		}

		my $dist_local=$min+$min_local;
		if (($dist_local < $dist) or ($dist==-1)) {

			foreach my $key_min (@min) {

				my %hash_tmp=%$hash;
				my %pset1=%$pset1;
				my %pset2=%$pset2;

				my ($iset1,$iset2)=split /\-/,$key_min;

				foreach my $key (keys %pset2) {

					delete $hash_tmp{"$iset1-$key"};
				}
				delete $pset1{$iset1};

				foreach my $key (keys %pset1) {

					delete $hash_tmp{"$key-$iset2"};
				}
				delete $pset2{$iset2};

				if (scalar keys %hash_tmp) {

					push @states,\%hash_tmp;
					push @min_states,$dist_local;

					push @pset1_states,\%pset1;
					push @pset2_states,\%pset2;

				} else {

					$dist=$dist_local;
				}
			}
		}
	}

	return $dist;
}

sub pdistance {

	my ($phrase1,$phrase2,$set,$distance,$optional_ref)=@_;
	my $mode;
	my $cost;

	if (!defined &$distance) {

		require Carp;
		Carp::croak("Text::PhraseDistance: a string distance subroutine is needed");
	}

	if ($optional_ref) {

		if (ref($optional_ref) ne "HASH") {

			warn "Text::PhraseDistance: options not well formed, using default";

		} else {

			foreach my $key (keys %$optional_ref) {

				if ($key eq "-cost") {

					$cost=$$optional_ref{'-cost'};
					if (ref($cost) ne "ARRAY") {

           					require Carp;
				      		Carp::croak("Text::PhraseDistance: -cost option requires an array");
					}

				} elsif ($key eq "-mode") {

					$mode=$$optional_ref{'-mode'};

				} else {

					require Carp;
					Carp::croak("Text::PhraseDistance: $key is not a valid option");
				}
			}
		}
	}

	$cost ||= [1,1];
	$mode='both' if ($mode eq '');

	my $pdistance;

	my ($set1_p1,$set2_p1)=_create_sets($phrase1,$set);
	my ($set1_p2,$set2_p2)=_create_sets($phrase2,$set);

	if ($mode eq 'complementary') {

		#only things that ARE NOT in $set are used to calculate the phrase distance

		$pdistance=_set_distance($cost,$set2_p1,$set2_p2,$distance);

	} elsif ($mode eq 'both') {

		#both things that ARE and ARE NOT in $set are used to calculate the phrase distance

		$pdistance=_set_distance($cost,$set1_p1,$set1_p2,$distance);
		$pdistance+=_set_distance($cost,$set2_p1,$set2_p2,$distance);

	} elsif ($mode eq 'set') {

		#only things that ARE in $set are used to calculate the phrase distance

		$pdistance=_set_distance($cost,$set1_p1,$set1_p2,$distance);

	} else {

		require Carp;
		Carp::croak("Text::PhraseDistance: -mode option must be 'complementary' or 'both' or 'set', not $mode");
	}

	return $pdistance;
}
	
1;

__END__

=head1 NAME

Text::PhraseDistance - A measure of the degree of proximity of 2 given phrases


=head1 SYNOPSIS

 use Text::PhraseDistance qw(pdistance);

 sub distance {

	#your own implementation of a distance between strings
	#
	#that needs 2 strings (2 arguments) and returns a number
 }

 # otherwise you can use Text::Levensthein or others, e.g.
 # use Text::Levenshtein qw(distance);

 my $phrase1="a yellow dog";
 my $phrase2="a dog yellow";

 my $set="abcdefghijklmnopqrstuvwxyz";

 print pdistance($phrase1,$phrase2,$set,\&distance);


=head1 DESCRIPTION


This module provides a way to compare two phrases and to give a measure of
their proximity. In this context, a phrase is a groups of words formed by
a set of characters, separated by elements from the complemetary of that set.
E.g. if the set is composed by [abcdefghijklmnopqrstuvwxyz], a phrase is
"hello, world!" where the words are "hello" and "world", with ", " and "!" parts 
of the complementary set.

This module does not provide a "classic" string distance (e.g. Levenshtein), i.e. a 
way to compare two strings as unique entities. 
Instead it uses a string distance to compare the words, one by one and it tries to
"match" the ones that have a smaller distance. It also calculates a positional distance
for every words belonging to the set and for the elements of the complementary set.
So for example, for the two phrases:

 "a yellow dog"
 "a dog yellow"

Levenshtein says that are distance 8.
Also for the phrases:

 "a yellow dog"
 "a good cat"

the Levenshtein distance is 8, but the first 2 phrases are much closer than the second.

With the phrase distance implemented in this module, using the
Text::Levenshtein as the string distance, the phrases:

 "a yellow dog"
 "a good cat"

have distance 8, but the phrases:

 "a yellow dog"
 "a dog yellow"

have distance 2.
This is because this module evaluates the string distance for the words that it
is 0 (because there are 3 pairs of words with minimal string distance equal to 0) 
and the positional distance, that is 0 for the two "a"s plus 1 for "yellow" in the 
first phrase compared with "yellow" in the second (i.e. they are distant 1 
position from each other), plus 1 for "dog" in the first phrase compared with "dog" 
in the second.

This 2 components of the phrase distance (i.e. the string distance and the
positional distance) can have a different cost from the default (that is 1 for both)
to give your own type of phrase distance (see below for the syntax).

By default, this module sums the phrase distance from the words from the set 
(i.e. formed by the defined set of characters) and the phrase distance calculated
from the "words" belonging the complementary set. In order to change this behaviour, 
see below.

The phrase distance implemented in this module is very slow because it
calculates the string distance n x m times, where n is the number of words in
the first phrase and m is the number of words in the second one.
Moreover, if there are a lot of minimums (i.e. pair of strings that have the smallest 
phrase distance in that moment), the algorithm has to do more iterations to find 
the best choice.


=head2 USAGE

You have to import the pdistance function to the current namespace:

 use Text::PhraseDistance qw(pdistance);


then you have to declare your distance function:

 sub distance {

	#your own implementation of a distance between strings
	#
	#that needs 2 strings (2 arguments) and returns a number
 }

otherwise you can use Text::Levensthein or others, e.g.

 use Text::Levenshtein qw(distance);


You need also the set of characters for the words, e.g.

 my $set="abcdefghijklmnopqrstuvwxyz";


and then the two phrases, e.g.:


 my $phrase1="a yellow dog";
 my $phrase2="a dog yellow";


so you can call the phrase distance:

 print pdistance($phrase1,$phrase2,$set,\&distance);


In order to define a custom distance subroutine, wrapping an existent one
(e.g. WagnerFischer with a custom array cost) you can use a closure
like this:

 my $mydistance;
 {
     my $array_ref = [0, 1, 2];
     $mydistance = sub { 
         distance( $array_ref, shift, shift );
     };
 }


=head2 OPTIONAL PARAMETERS

 pdistance($phrase1,$phrase2,$set,\&distance,{-cost=>[1,0],-mode=>'set'});

 -mode	
 accepted values are: 	
	complementary	means that the distance is calculated only
			from the "words" from the complementary set
					
	both	default, the distance is calculated from both sets

	set	means that the distance is calculated only
		from the "words" from the given set

 -cost
 accepted value is an array with 2 elements: first is the cost for
 the string distance and the second is the cost for positional distance.
 Default array is [1,1] .


=head1 THANKS

Many thanks to Stefano L. Rodighiero <F<larsen at perlmonk.org>> and 
to D. Frankowski for the suggestions.


=head1 AUTHOR

Copyright 2002 Dree Mistrut <F<dree@friul.it>>

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under 
the same terms as Perl itself.


=head1 SEE ALSO

C<Text::Levenshtein>, C<Text::WagnerFischer>


=cut

