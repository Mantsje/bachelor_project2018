module graph::Grammar2Graph

import Grammar;
import analysis::graphs::Graph;

import graph::SymbolDependencies;
import graph::Kosaraju;

//Generates directed graph of dependent components, does recursive search in all symbols except conditions of conditionals
Graph[Symbol] grammar2graph(Grammar g) {
	out = {};
	for(/prod(Symbol s,[_*,Symbol elem,_*],_) := g, (label(_,Symbol from) := s || Symbol from := s), 
					from is sort || from is lex || from is \parameterized-sort || from is \parameterized-lex 
								 || from is layouts) {
		for (to <- getDeepestSymbols(elem), to is sort || to is lex || to is \parameterized-lex ||
		 									to is \parameterized-sort || to is layouts)
			out += <from, to>;
		out += <from, from>;
	}
	return out;
} 
	
//Generates the set of strongly connected components from a grammar definition
set[set[Symbol]] grammar2strConnectedComponents(Grammar g) {
	return stronglyConnectedComponents(grammar2graph(g));
}
