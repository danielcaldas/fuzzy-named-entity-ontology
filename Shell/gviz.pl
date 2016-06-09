#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use GraphViz2;
use Data::Dumper;
use Data::Undump;

# Global entities configs
my $title_label = "fuzzy named entity ontology";
my %entities_configs = (
"PESSOA" => (color => "green"),
"CIDADE" => (color => "blue"),
"DATA" => (color => "red"),
"PAIS" => (color => "brown")
);

# ../graph.dump
#my %graph =
load_graph($ARGV[0]);

#print Dumper \%graph;

sub load_graph {
  my ( $file ) = @_;
  open(my $fh, "<", $file) or die "Can't open file ".$file." !\n";
  while (<$fh>) {
    chomp;
    my $a = eval($_);
    print $a->{'type'};
  }
}


__END__


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
