#!/usr/bin/perl

use utf8::all;
use warnings;
use strict;
use Data::Dumper;
#use FL3 'pt';
use XML::LibXML;

# Gazeteers
my %paises = load_gazeteer('./Gazeteer/paises.txt');
my %cidades_pt = load_gazeteer('./Gazeteer/cidades_portuguesas.txt');
my %cidades_an = load_gazeteer('./Gazeteer/cidades_angolanas.txt');
my %nomes = load_gazeteer('./Gazeteer/nomes.txt');

# Dicionario
my $dic = Lingua::Jspell->new("pt");

# Parse XML igual ao anterior
my $xml_src = $ARGV[0];

my $parser = XML::LibXML->new;
my $doc = $parser->parse_file($xml_src);
my @nodeList = $doc->getElementsByTagName('news');

print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<newsdb>\n";
foreach my $news (@nodeList) 
{
	print "<".$news->nodeName().">\n";
	foreach my $tag ($news->childNodes()) 
	{
		my $tagname = $tag->nodeName();
		if(!($tagname =~ "text")) 
		{
			# Tipar entidades numa tag
			entities_typing($tagname, $news->getElementsByTagName($tagname));
		}
	}
	print "</".$news->nodeName().">\n";
}
print "</newsdb>\n";

sub entities_typing 
{
	my $tag = shift;
	my $texto = shift;

	print "<$tag>";
	foreach my $elem ($texto->childNodes()) 
	{
		if($elem->nodeName() =~ "text") 
		{
			print "$elem ";
		}
		else
		{
			if($elem =~ /<ENT id="([0-9]+)" tag="([^"]*)">([^<]*)<\/ENT>/)
			{
				my $id = $1;
				my $t = $2;
				my $ent = $3;

				# Reconhecer tipo com a tag freeling
				my $type = rec_type($t,$ent);
				print "<ENT id=\"$id\" tag=\"$t\" type=\"$type\">$ent</ENT> ";
			}
		}
	}
	print "</$tag>\n";
}

sub rec_type
{	
	#TIPOS: PESSOA, CIDADE, PAIS, DATA, UNDEF

	my $tag = shift;
	my $ent = shift;
	my $type = "UNDEF";

	if($tag =~ /NP0000/)
	{
		if(in_gazeteer($ent,\%paises) or in_jspell($ent,$dic,'country')) 
		{ 
			$type = 'PAIS'; 
		}

		if(in_gazeteer($ent,\%cidades_pt) or in_jspell($ent,$dic,'cid')) 
		{ 
			$type = 'CIDADE'; 
		}
		
		if(in_gazeteer($ent,\%cidades_an) or in_jspell($ent,$dic,'cid')) 
		{ 
			$type = 'CIDADE'; 
		}
		
		my $firstword = (split(/ /,$ent))[0];
		if(in_gazeteer($firstword,\%nomes) or in_jspell($ent,$dic,'p')) 
		{ 
			$type = 'PESSOA'; 
		}
	}
	elsif($tag =~ /W/)
	{
		$type = "DATA";
	}

	return $type;
}

sub in_jspell
{
	my $ent = shift;
	my $dic = shift;
	my $sem = shift;

	my @forms = $dic->fea($ent);
	my %form = %{$forms[0]};
	
	if($form{'CAT'} =~ /np/ and $form{'SEM'} =~ /$sem/)
	{
		return 1;
	}
	else 
	{
		return 0;
	}
}

sub in_gazeteer
{
	my $ent = shift;
	my $gaz = shift;
	my %gazeteer = %$gaz;

	if(exists $gazeteer{lc $ent}) { return 1; }
	else { return 0; }
}

sub load_gazeteer 
{
	my $file = shift;
	-f $file or die $!;
	
	my %gazeteer;
	
	open(F,'<:encoding(UTF-8)',$file) or die $!;
	while(<F>)
	{
		while($_ =~ /\w+([ \-]\w+)*/g)
		{
			$gazeteer{lc $&} = $&;
		}
	}
	close(F);

	return %gazeteer;
}




