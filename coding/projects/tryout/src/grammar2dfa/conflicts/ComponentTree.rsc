module grammar2dfa::conflicts::ComponentTree

import Prelude;
import analysis::graphs::Graph;

import graph::Grammar2Graph;
import grammar2dfa::automata::StateMachine;

alias NTree[&T] = tuple[&T root, map[&T val, set[&T] children] mapping];


NTree[set[Symbol]] generateComponentTree(set[set[Symbol]] components, Graph[Symbol] dependencies, set[Symbol] startComponent) {
	map[Symbol, set[Symbol]] sym_to_comp = (s:comp | comp <- components, s <- comp);
	NTree[set[Symbol]] tree = <startComponent, (comp:{} | comp <- components)>;
	for (comp <- tree.mapping) {
		for(sym <- comp) {
			for(to <- dependencies[sym]) {
				if (to notin comp) tree.mapping[comp] += {sym_to_comp[to]};
			}
		}
	}
	return tree;
}

NTree[set[Symbol]] toComponentTree(Grammar g) {
	assert(size(g.starts) == 1);
	components = grammar2strConnectedComponents(g);
	graph = grammar2graph(g);
	startcomp = takeOneFrom({c | c <- components, takeOneFrom(g.starts)[0] in c})[0];
	return generateComponentTree(components, graph, startcomp);
}