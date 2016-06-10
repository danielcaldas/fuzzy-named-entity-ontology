#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use GraphViz2;
use Data::Dumper;
use XML::LibXML;

# Global entities configs
my $title_label = "fuzzy named entity ontology";
my %entities_configs = (
"PESSOA" => { color => "green", shape => "circle" },
"CIDADE" => { color => "blue", shape => "circle" },
"DATA" => { color => "red", shape => "circle" },
"PAIS" => { color => "brown", shape => "circle" }
);

# Load graph into mem
my %graph_content = load_xml_graph("../graph.xml");

# print Dumper \%graph;

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
  print Dumper(\@command);
  if($command[0] eq "list") {
    if($command[1] eq "entidades") {
      list_entities();
    }
  }
  print "\n> ";
}

# List all loaded entities
sub list_entities {
  for my $k (keys %graph_content) {
      print "$k  ".$graph_content{$k}{type}."\n";
  }
}

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
