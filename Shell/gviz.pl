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

# Create nodes
for my $k (keys %graph_content) {
    my $etype = $graph_content{$k}{type};
    # print $entities_configs{$etype}{shape}."\n";
    $graph->add_node(name => $k, shape => $entities_configs{$etype}{shape}, color => $entities_configs{$etype}{color});
}

for my $k (keys %graph_content) {
  my %rels = %{$graph_content{$k}{rels}};
  for my $rel (keys %rels ) {
      $graph->add_edge(from=>$k, to=>$rel, arrowsize=>$rels{$rel});
  }
}
# Create connections
# $graph -> add_edge(from => 'Murrumbeena', to    => 'Carnegie', arrowsize => 2);
# $graph -> add_edge(from => 'Murrumbeena', to    => 'Oakleigh', color => 'brown');

# Generate and Pop up graph
my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "sub.graph.$format");

$graph -> run(format => $format, output_file => $output_file);

exec("eog html/sub.graph.$format");


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


print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<newsdb>\n";
foreach my $news (@nodeList) {
  print "<".$news->nodeName().">\n";
  foreach my $tag ($news->childNodes()) {
    my $tagname = $tag->nodeName();
    if(! ($tagname =~ "text") ) {
      entities_marker($tagname, $news->getElementsByTagName($tagname)->string_value);
    }
  }
  print "</".$news->nodeName().">\n";
}
print "</newsdb>\n";



my ($graph) = GraphViz2 -> new
(
edge   => {color => 'grey'},
global => {directed => 0},
graph  => {label => $title_label, rankdir => 'TB'},
node   => {shape => 'oval'},
);



$graph -> add_node(name => 'Carnegie', shape => 'circle');
$graph -> add_node(name => 'Murrumbeena', shape => 'box', color => 'green');
$graph -> add_node(name => 'Oakleigh',    color => 'blue');

$graph -> add_edge(from => 'Murrumbeena', to    => 'Carnegie', arrowsize => 2);
$graph -> add_edge(from => 'Murrumbeena', to    => 'Oakleigh', color => 'brown');

$graph -> push_subgraph
(
name  => 'cluster_1',
graph => {label => 'Child'},
node  => {color => 'magenta', shape => 'diamond'},
);

$graph -> add_node(name => 'Chadstone', shape => 'hexagon');
$graph -> add_node(name => 'Waverley', color => 'orange');

$graph -> add_edge(from => 'Chadstone', to => 'Waverley');

$graph -> pop_subgraph;

$graph -> default_node(color => 'cyan');

$graph -> add_node(name => 'Malvern');
$graph -> add_node(name => 'Prahran', shape => 'trapezium');

$graph -> add_edge(from => 'Malvern', to => 'Prahran');
$graph -> add_edge(from => 'Malvern', to => 'Murrumbeena');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "sub.graph.$format");

$graph -> run(format => $format, output_file => $output_file);

exec("eog html/sub.graph.$format");
