#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use FL3 'pt';

#<:encoding(iso-8859-1)
my $texto;
{
	open my $fh, "<:utf8", "Corpus/mini_corpus_pt.xml" or die "can not open file!\n";
	local $/=undef;
	$texto = <$fh>;
	close $fh;
}
binmode STDOUT, ":utf8";
# Atomizacao
my $tokens = tokenizer->tokenize($texto);
my $frases = splitter->split($tokens);

#Analise morfologica
$frases = morph->analyze($frases, NERecognition => 0);

# Etiquetacai POS(''Part of Speech'') usando Hidden Markov Models

#$frases = hmm->tag($frases);

#$frases = relax->tag($frases);

for my $f(@$frases) {
	my @words = $f->words;
	for my $w(@words) {
		my $h = $w->as_hash();
		print join("\t", map { $h->{$_} } (qw.form lemma tag.)), "\n";
	}
}

__END__
$frases = chart->parse($frases);
for my $f(@$frases) {
	print $f->to_text, "\n";
	if($f->is_parsed) {
		my $parseTree = $f->parse_tree;
		print $parseTree->dump;
	}
}

for my $f(@$frases) {
	my @words = $f->words();
	for my $w(@words) {
		my $h = $w->as_hash();
		print Dumper($h);
	}
}
