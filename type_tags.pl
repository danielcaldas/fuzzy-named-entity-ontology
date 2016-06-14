#!/usr/bin/perl

use utf8::all;
use warnings;
use strict;
use Data::Dumper;
#use FL3 'pt';
use XML::LibXML;
use Lingua::Jspell;

# Gazeteers
my %paises = load_gazeteer('./Gazeteer/paises.txt');
my %cidades_pt = load_gazeteer('./Gazeteer/cidades_portuguesas.txt');
my %cidades_an = load_gazeteer('./Gazeteer/cidades_angolanas.txt');
my %nomes = load_gazeteer('./Gazeteer/nomes.txt');

# Dicionarios
my $dic_pt = Lingua::Jspell->new("pt");
my $dic_en = Lingua::Jspell->new("en");

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
				
				if($type =~ /DATA/) { $ent = normalize_date($ent); }
				print "<ENT id=\"$id\" type=\"$type\">$ent</ENT> ";
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
		if(in_gazeteer($ent,\%paises) or in_jspell($ent,$dic_pt,'country') or in_jspell($ent,$dic_en,'country')) 
		{ 
			$type = 'PAIS'; 
		}

		if(in_gazeteer($ent,\%cidades_pt) or in_jspell($ent,$dic_pt,'cid') or in_jspell($ent,$dic_en,'cid')) 
		{ 
			$type = 'CIDADE'; 
		}
		
		if(in_gazeteer($ent,\%cidades_an) or in_jspell($ent,$dic_pt,'cid') or in_jspell($ent,$dic_en,'cid')) 
		{ 
			$type = 'CIDADE'; 
		}
		
		my $firstword = (split(/ /,$ent))[0];
		if(in_gazeteer($firstword,\%nomes) or in_jspell($ent,$dic_pt,'p') or in_jspell($ent,$dic_en,'p')) 
		{ 
			$type = 'PESSOA'; 
		}
	}
	elsif($tag =~ /W/ and is_date($ent))
	{
		$type = "DATA";
	}

	return $type;
}

sub is_date
{
	my $ent = shift;
	
	my $mes = 'janeiro|fevereiro|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro';
	my $reg1 = qr{[0-9]+ de ($mes) de [0-9][0-9][0-9][0-9]};
	my $reg2 = qr{[0-9]+\/[0-9]+\/[0-9][0-9][0-9][0-9]};
	my $reg3 = qr{[0-9]+ de ($mes)};
	my $reg4 = qr{($mes) de [0-9][0-9][0-9][0-9]};
	my $reg5 = qr{[0-9][0-9][0-9][0-9]\/[0-9][0-9]\/[0-9][0-9]};

	if($ent =~ /$reg1|$reg2|$reg3|$reg4|$reg5/i) { return 1; }
	else { return 0; }
}

sub normalize_date
{
	my $ent = shift;
	
	my $mes = 'janeiro|fevereiro|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro';
	my $reg1 = qr{([0-9]+) de ($mes) de ([0-9][0-9][0-9][0-9])};
	my $reg2 = qr{([0-9]+)\/([0-9]+)\/([0-9][0-9][0-9][0-9])};
	my $reg3 = qr{([0-9]+) de ($mes)};
	my $reg4 = qr{($mes) de ([0-9][0-9][0-9][0-9])};
	
	if($ent =~ /$reg1/i) { $ent = sprintf("%s/%s/%s",$3,mes_to_num($2),$1); }
	elsif($ent =~ /$reg2/i) { $ent = sprintf("%s/%s/%s",$3,$2,$1); }
	elsif($ent =~ /$reg3/i) { $ent = sprintf("%s/%s",mes_to_num($2),$1); }
	elsif($ent =~ /$reg4/i) { $ent = sprintf("%s/%s",$2,mes_to_num($1)); }

	return $ent;
}

sub mes_to_num
{
	my $mes = shift;

	if($mes =~ /janeiro/i) { return "01"; }
	elsif($mes =~ /fevereiro/i) { return "02"; }
	elsif($mes =~ /março/i) { return "03"; }
	elsif($mes =~ /abril/i) { return "04"; }
	elsif($mes =~ /maio/i) { return "05"; }
	elsif($mes =~ /junho/i) { return "06"; }
	elsif($mes =~ /julho/i) { return "07"; }
	elsif($mes =~ /agosto/i) { return "08"; }
	elsif($mes =~ /setembro/i) { return "09"; }
	elsif($mes =~ /outubro/i) { return "10"; }
	elsif($mes =~ /novembro/i) { return "11"; }
	elsif($mes =~ /dezembro/i) { return "12"; }
}

sub in_jspell
{
	my $ent = shift;
	my $dic = shift;
	my $sem = shift;

	my @forms = $dic->fea($ent);
	my %form;

	if(scalar @forms) 
	{ 
		%form = %{$forms[0]};
	
		if(exists $form{'CAT'} and exists $form{'SEM'} and $form{'CAT'} =~ /np/ and $form{'SEM'} =~ /$sem/)
		{
			return 1;
		}
		else { return 0; }
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




