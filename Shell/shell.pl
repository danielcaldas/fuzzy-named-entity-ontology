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
my $title_label = "fuzzy named entity ontology";
my %entities_configs = (
"PESSOA" => { color => "green", shape => "circle" },
"CIDADE" => { color => "blue", shape => "circle" },
"DATA" => { color => "red", shape => "circle" },
"PAIS" => { color => "brown", shape => "circle" }
);

# Load graph into mem
my %graph_content = load_xml_graph("../graph.xml");
my %graph_nodes;

my ($graph) = GraphViz2 -> new
(
edge   => {color => 'grey'},
global => {directed => 0},
graph  => {label => $title_label, rankdir => 'TB'},
node   => {shape => 'oval'},
);

# Shell
print "> ";
while(<>) {
  chomp $_;
  my @command = split / /, $_;
  if($command[0] eq "list") {
    if($command[1] eq "entidades") {
      list_entities();
    }
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
  $graph->add_node(name => $ent, shape => $entities_configs{$etype}{shape}, color => $entities_configs{$etype}{color});
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
  # draw_entity_graph_edges($ent,$depth);
  generate_graph();
}

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

sub generate_graph {
  # Generate and Pop up graph in parallel process
  my($format)      = 'svg';
  my($output_file) = File::Spec->catfile('out', "sub.graph.$format");
  $graph -> run(format => $format, output_file => $output_file);
  print "\n[PRIMA ENTER]\n";
  $pm->start and next;
  system("gnome-terminal -x sh -c 'eog out/sub.graph.$format'");
  $pm->finish;
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

sub print_help_menu {
  print "\n\tlist entidades - listar entidades e respetivo tipo\n";
  print "\tdump nome_da_entidade - mostrar detalhe de uma dada entidade (se o nome da entidade tiver espacos substituir por _)\n";
}
__END__
# Create nodes
for my $k (keys %graph_content) {
  my $etype = $graph_content{$k}{type};
  $graph->add_node(name => $k, shape => $entities_configs{$etype}{shape}, color => $entities_configs{$etype}{color});
}

for my $k (keys %graph_content) {
  my %rels = %{$graph_content{$k}{rels}};
  for my $rel (keys %rels ) {
    $graph->add_edge(from=>$k, to=>$rel, arrowsize=>$rels{$rel});
  }
}

# Generate and Pop up graph
my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('out', "sub.graph.$format");

$graph -> run(format => $format, output_file => $output_file);

exec("eog out/sub.graph.$format");
