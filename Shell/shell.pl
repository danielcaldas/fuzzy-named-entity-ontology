#!/usr/bin/env perl

use strict;
#use warnings;
no warnings "all";
use File::Spec;
use GraphViz2;
use Data::Dumper;
use XML::LibXML;
use Parallel::ForkManager;

my $MAX_PROCESSES = 5;

# Global entities configs
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);
my $title_label = "fuzzy named entity ontology\nLegenda: Verde - Pessoas, Azul - Cidades, Vermelho - Datas, Castanho - Paises, Amarelo - Entidade Principal";
my %entities_configs = (
  "PESSOA" => { color => "green", shape => "circle" },
  "CIDADE" => { color => "blue", shape => "circle" },
  "DATA" => { color => "red", shape => "circle" },
  "PAIS" => { color => "brown", shape => "circle" },
  "MAIN" => { color => "yellow", shape => "circle" }
);

# Load graph into mem
my %graph_content = load_xml_graph("../graph.xml");
my %graph_nodes;

my ($graph) = GraphViz2 -> new
(
  edge   => {color => 'grey'},
  global => {directed => 0},
  graph  => {label => $title_label, rankdir => 'TB'},
  node   => { shape => 'oval', style => 'filled'},
);

# Shell
print "> ";
while(<>) {
  chomp $_;
  my @command = split / /, $_;
  if($command[0] eq "list") {
    list_entities();
  }
  if($command[0] eq "dump") {
    if( !($command[1] eq "") ) {
      dump_entity($command[1]);
    } else {
      print "\n\tFalta um argumento (nome da entidade substituindo os espacos por _)\n";
    }
  }
  elsif($command[0] eq "graph") {
    my $depth = 1;
    $command[1] =~ s/_/ /g;
    if(exists $graph_content{$command[1]}) {
      if($command[2]) {
        $depth += $command[2];
      }
      draw_entity_graph($command[1],$depth);
    }
    else {
      print "\n\tA entidade [".$command[1]."] nao existe\n";
    }
  }
  elsif($command[0] eq "help") {
    print_help_menu();
  }
  print "\n> ";
}

# List all loaded entities
sub list_entities {
  for my $k (keys %graph_content) {
    print "$k  ".$graph_content{$k}{type}."\n";
  }
}

# Dump some entity by name
sub dump_entity {
  my $ent = shift;
  $ent =~ s/_/ /g;
  if(exists $graph_content{$ent}) {
    print Dumper(\%{$graph_content{$ent}});
  } else {
    print "\n\tA entidade [$ent] nao existe.\n";
  }
}

# Draw the graph for a certain entity with a given depth
sub draw_entity_graph {
  my ($ent,$depth) = @_;

  my %ent_rels = %{$graph_content{$ent}{rels}};
  my $etype = $graph_content{$ent}{type};
  $graph->add_node(name => $ent, shape => $entities_configs{"MAIN"}{shape}, color => $entities_configs{"MAIN"}{color});
  $graph_nodes{$ent}++;
  # Nodes
  for my $k (keys %ent_rels) {
    if($depth > 0) {
      draw_entity_graph_nodes($k,$depth);
    }
  }
  # Edges
  for my $k (keys %graph_nodes) {
    my %k_rels = %{$graph_content{$k}{rels}};
    for my $k_rel (keys %k_rels) {
      if(exists $graph_nodes{$k_rel}) {
        $graph->add_edge(from=>$k, to=>$k_rel, arrowsize=>$k_rels{$k_rel});
      }
    }
  }
  generate_graph($ent);
  undef %ent_rels;
  reset_graph();
}

# Draw all the entity nodes related with a certain depth value
sub draw_entity_graph_nodes {
  my ($ent,$depth) = @_;
  my $etype = $graph_content{$ent}{type};
  if($depth > 0) {
    if(!(exists $graph_nodes{$ent})) {
      $graph->add_node(name => $ent, shape => $entities_configs{$etype}{shape}, color => $entities_configs{$etype}{color});
      $graph_nodes{$ent}++;
    }
    if($depth > 1) {
      my %ent_rels = %{$graph_content{$ent}{rels}};
      for my $rel (keys %ent_rels) {
        draw_entity_graph_nodes($rel,$depth-1);
      }
    }
  }
}

# Generate and Pop up graph in parallel process
sub generate_graph {
  my $ent = shift;
  my($format)      = 'svg';
  my($output_file) = File::Spec->catfile('out', "$ent.graph.$format");
  $graph -> run(format => $format, output_file => $output_file);
  print "\n[PRIMA ENTER]\n";
  $pm->start and next;
  system("gnome-terminal -x sh -c 'eog out/$ent.graph.$format'");
  $pm->finish;
}

# Reset all graph related variables
sub reset_graph {
  undef %graph_nodes;
  undef $graph;
  $graph = GraphViz2 -> new
  (
    edge   => {color => 'grey'},
    global => {directed => 0},
    graph  => {label => $title_label, rankdir => 'TB'},
    node   => { shape => 'oval', style => 'filled'},
  );
}

# Print help menu
sub print_help_menu {
  print "\n\tlist - listar entidades e respetivo tipo\n";
  print "\tdump [nome_entidade] - mostrar detalhe de uma dada entidade (se o nome da entidade tiver espacos substituir por _)\n";
  print "\tgraph [nome_entidade] [(depth)?] - desenhar o grafo de uma dada entidade ()o parametro da profundidade e opcional, o valor por defeito e 1\n";
}

# Load the entities graph from a XML source
sub load_xml_graph {
  my ( $file ) = @_;

  my $parser = XML::LibXML->new;
  my $doc = $parser->parse_file($file);
  my @nodeList = $doc->firstChild()->childNodes();
  my %graph;
  foreach my $node (@nodeList) {
    my ($entity,$type);
    foreach my $childNode ($node->childNodes()) {
      my $nodeName = $childNode->nodeName();
      if(! ($nodeName =~ "text") ) {
        if($nodeName eq "entity") {
          $entity = $node->getElementsByTagName('entity')->string_value;
          $graph{$entity}{type} = "";
        } elsif($nodeName eq "type") {
          $type = $node->getElementsByTagName('type')->string_value;
        } else {
          $graph{$entity}{type} = $type;
          my @entity_rels = $childNode->childNodes();
          my ($ent,$weight);
          foreach my $rel (@entity_rels) {
            if(! ($rel->nodeName() =~ "text") ) {
              $graph{$entity}{rels}{$rel->getElementsByTagName("ent")->string_value}
              =$rel->getElementsByTagName("weight")->string_value;
            }
          }
        }
      }
    }
  }
  return %graph;
}
