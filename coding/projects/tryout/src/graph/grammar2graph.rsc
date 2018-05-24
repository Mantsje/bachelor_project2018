module graph::grammar2graph

import Grammar;
import analysis::graphs::Graph;
import analysis::grammars::Dependency;

import graph::Kosaraju;

//Generates directed graph of dependant components
Graph[Symbol] grammar2graph(Grammar g) 
	= symbolDependencies(g);
	
//Generates the set of strongly connected components from a grammar definition
set[set[Symbol]] grammar2strConnectedComponents(Grammar g) {
	return stronglyConnectedComponents(grammar2graph(g));
}