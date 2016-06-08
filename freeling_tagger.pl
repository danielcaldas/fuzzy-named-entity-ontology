#!/usr/bin/perl

use utf8::all;
use warnings;
use strict;
use Data::Dumper;
use FL3 'pt';
use XML::LibXML;

my $xml_src = $ARGV[0];

my $parser = XML::LibXML->new;
my $doc = $parser->parse_file($xml_src);
my @nodeList = $doc->getElementsByTagName('news');

my %fl_tags = ( "NP00000" => 1, "W" => 1 );
my $id=1;

print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<newsdb>\n";
foreach my $news (@nodeList) {
	print "<".$news->nodeName().">\n";
	foreach my $tag ($news->childNodes()) {
		my $tagname = $tag->nodeName();
		if(! ($tagname =~ "text") ) {
			entities_marker($tagname, $news->getElementsByTagName($tagname)->string_value());
		}
	}
	print "</".$news->nodeName().">\n";
}
print "</newsdb>\n";

sub entities_marker {
	my $tag = shift;
	my $texto = shift;

	# Atomizacao
	my $tokens = tokenizer->tokenize($texto);
	my $frases = splitter->split($tokens);

	#Analise morfologica
	$frases = morph->analyze($frases);

	# Etiquetacai POS(''Part of Speech'') usando Hidden Markov Models
	$frases = hmm->tag($frases);
	#$frases = relax->tag($frases);

	print "<$tag>";
	for my $f (@$frases) {
		my @words = $f->words;
		for my $w (@words) {
			my $h = $w->as_hash();
			$h->{form} =~ s/_/ /g;
			if(exists $fl_tags{$h->{tag}}) {
				print "<END id='$id' type='".$h->{tag}."'>".$h->{form}."</ENT> ";
			} else {
				print $h->{form}." ";
			}
			$id++;
		}
	}
	print "</$tag>\n";
}
