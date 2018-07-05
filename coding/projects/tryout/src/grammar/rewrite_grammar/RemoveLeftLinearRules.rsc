module grammar::rewrite_grammar::RemoveLeftLinearRules

import Prelude;
import analysis::graphs::Graph;

import graph::Grammar2Graph;
import grammar::strongly_regular_grammar::InSubSymbol;
import grammar::rewrite_grammar::RewriteRules;

//Gets all productions rules in the form \prod from a grammar, as a side-effect removes all attributes
set[Production] getRulesOfComp(Grammar g, set[Symbol] component) {
	set[Production] rules_out = {};
	for(rule <- {g.rules[sym] | sym <- component}) {
		switch (rule) {
			case p:\prod(Symbol lhs, list[Symbol] rhs, _): {
				rules_out += \prod(lhs, rhs, {});
			} case \choice(_, set[Production] choices): {
				rules_out += {\prod(lhs, rhs, {}) | \prod(Symbol lhs, list[Symbol] rhs, _) <- choices};
			} default: {
				throw error("Non-Exhaustive pattern match in getRulesOfComp: <rule>");
			}
		}
	}
	return rules_out;
}

/* Check if the rules are all left-linear */
bool areLeftLinear(set[Production] rules, set[Symbol] wrt) {
	for (r <- rules) {
		switch(r) {
			case \prod(_, list[Symbol] rhs, _): {
				//How many non-terminals in M are in r's rhs?
				int nonTermsInM = (0 | it + 1 | elem <- rhs, isSubSymbolInComponent(elem, wrt)[0]);
				if (nonTermsInM == 1) {
					if (!(isSubSymbolInComponent(getFirstFrom(rhs), wrt)[0])) {
						return false;
					}
				} else if (nonTermsInM > 1) {
					return false;
				}
			} default: {
				throw error("found a rule that was not just \"\\prod()\" : <r>");
			}
		}
	}
	return true;
}

set[Symbol] findAllStarts(set[Symbol] comp, Graph[Symbol] graph) {
	out = {};
	for(<from, to> <- graph) {
		if(to in comp && from notin comp) out += from;
	}
	return out;
}

Grammar removeFromComponent(set[Production] rules, set[Symbol] comp, set[Production] all_rules, Grammar g, Graph[Symbol] graph) {
	set[Production] new_rules;
	set[Symbol] allStarts = findAllStarts(comp, graph);
	for (r <- rules) {
		switch(r) {
			case \prod(_, list[Symbol] rhs, _): {
					//if (!(isSubSymbolInComponent(getFirstFrom(rhs), comp)[0])) {
					println();
			} default: {
				throw error("found a rule that was not just \"\\prod()\" : <r>");
			}
		}
	}
	return g;
}

Grammar removeLeftLinearity(Grammar g) {
	comps = grammar2strConnectedComponents(g);
	graph = grammar2graph(g);
	all_rules = getRewrittenRules(g);
	for (comp <- comps) {
		set[Production] rulesOfComp = getRulesOfComp(g, comp);
		if (areLeftLinear(rulesOfComp, comp)) {
			g = removeFromComponent(rulesOfComp, comp, all_rules, g, graph);
		}
	}
}