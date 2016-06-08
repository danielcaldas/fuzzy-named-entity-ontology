#!/usr/bin/perl

use utf8::all;
use warnings;
use strict;
use Data::Dumper;
use FL3 'pt';
use XML::LibXML;

my $parser = XML::LibXML->new;
my $doc = $parser->parse_file('Corpus/mini_corpus_pt.xml');

my @nodeList = $doc->getElementsByTagName('news');
foreach my $news (@nodeList) {
	my $t = $news->getElementsByTagName('title');
	print $t."\n";
}

__END__

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
$frases = morph->analyze($frases);

# Etiquetacai POS(''Part of Speech'') usando Hidden Markov Models
$frases = hmm->tag($frases);
#$frases = relax->tag($frases);

my $id=1;
for my $f (@$frases) {
	my @words = $f->words;
	for my $w (@words) {
		my $h = $w->as_hash();
		# print Dumper($h);
		if($h->{tag} eq ("NP00000") || $h->{tag} eq ("W") || $h->{tag} eq ("W")) {
			print "<END id='$id' type='".$h->{tag}."'>".$h->{form}."</ENT> ";
		} else {
			print $h->{form}." ";
		}
		#print join("\t", map { $h->{$_} } (qw.form lemma tag.)), "\n";
		$id++;
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
