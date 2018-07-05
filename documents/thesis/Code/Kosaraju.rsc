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
		<sub_components, sub_passed> = assign(G, inverted, u, u, components, passed);
		components += sub_components;
		passed += sub_passed;
	}
	return range(components);
}