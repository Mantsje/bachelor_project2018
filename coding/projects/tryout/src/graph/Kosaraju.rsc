module graph::Kosaraju

import Map;
import Relation;
import analysis::graphs::Graph;
import Set;
import List;

private tuple[list[&T], set[&T]] visitNode(Graph[&T] G, set[&T] visited, &T u) {
	list[&T] L = [];
	if (!(u in visited)) {
		visited += u;
		for (v <- G[u]) {
			<sub_L, sub_visited> = visitNode(G, visited, v);
			L = sub_L + L;
			visited = sub_visited;
		}
		L = u + L;
	}
	return <L, visited>;
}

private tuple[map[&T, set[&T]], set[&T]] assign(Graph[&T] G, Graph[&T] inverted, &T u, &T root, map[&T, set[&T]] components, set[&T] passed) {
	if (!(u in passed)) {
		if (root in components) components[root] += u; else components[root] = {u};
		passed += u;
		for (v <- inverted[u]) {
			<components, passed> += assign(G, inverted, v, root, components, passed);
		}
	}
	return <components, passed>;
}

@doc{
.Synopsis
Determine the strongly connected components of a graph, using Kosaraju's algorithm

.Description
Returns the https://en.wikipedia.org/wiki/Strongly_connected_component[strongly connected components] of Graph `G`, as sets of nodes. All nodes within one component are all reachable from one another, there are possible paths between two nodes from different components, however only one way. The graph is assumed to be directed.

.Examples
[None]
}
public set[set[&T]] stronglyConnectedComponents(Graph[&T] G) {
	set[&T] visited = {};
	list[&T] L = [];	
	for (u <- domain(G)) {
		<sub_L, sub_visited> = visitNode(G, visited, u);
		L = sub_L + L;
		visited = sub_visited;
	}
	map[&T, set[&T]] components = ();
	set[&T] passed = {};
	Graph[&T] inverted = invert(G);
	for (u <- L) {
		<components, passed> += assign(G, inverted, u, u, components, passed);
	}
	return range(components);
}


