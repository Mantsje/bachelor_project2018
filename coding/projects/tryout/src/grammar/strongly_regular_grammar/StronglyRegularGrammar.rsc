module grammar::strongly_regular_grammar::StronglyRegularGrammar

import Prelude;
import analysis::graphs::Graph;

import graph::Grammar2Graph;
import grammar::rewrite_grammar::ToPlainGrammar;
import grammar::strongly_regular_grammar::InSubSymbol;

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

/* Check if the rules are either all left-linear or all right-linear
 */
bool shouldRulesChange(set[Production] rules, set[Symbol] wrt) {
	bool right_linear = true;
	bool left_linear = true;
	for (r <- rules) {
		switch(r) {
			case \prod(_, list[Symbol] rhs, _): {
				//How many non-terminals in M are in r's rhs?
				int nonTermsInM = (0 | it + 1 | elem <- rhs, isSubSymbolInComponent(elem, wrt)[0]);
				if (nonTermsInM == 1) {
					if (!(isSubSymbolInComponent(last(rhs), wrt)[0])) {
						right_linear = false;
					}
					if (!(isSubSymbolInComponent(getFirstFrom(rhs), wrt)[0])) {
						left_linear = false;
					}
				} else if (nonTermsInM > 1) {
					right_linear = false;
					left_linear = false;
				}
			} default: {
				throw error("found a rule that was not just \"\\prod()\" : <r>");
			}
		}
	}
	
	if(right_linear) return false;
	if(left_linear) { println("Warning: set of left-linear tokens found, this could crash the grammar2dfa algorithm!"); return false; }
	return true;
}

/* Create for all symbols in a set a closing symbol: symbol_end.
 * Check if it already exists, if so, throw an error
 */
SymbolDelimiters constructSymbolDelimiters(Grammar g, set[Symbol] symbols) {
	SymbolDelimiters result = ();
	for (sym <- symbols) {
		str closeName = "<type(sym, ())>_end";
		if(sort(closeName) in domain(g.rules)) {
			throw error("tried to construct symbol: \"<closeName>\", it already existed in the inputgrammar,
				    'this lead to conflicts in generating the regular approximation.
				    'Consider changing the naming of your syntax");
		}
		switch(sym) {
			case \sort(_) :{
				result[sym] = sort(closeName);			
			} case \lex(_): {
				result[sym] = lex(closeName);
			} case \layouts(_): {
				result[sym] = layouts(closeName);
			} default: {
				throw error("non-exhaustive pattern match in constructSymbolDelimiters! <sym>");
			}
		}
	}
	return result;
}


bool isDirectlyReachableFrom(Symbol target, set[Symbol] component, Graph[Symbol] graph) {
	inv = invert(graph);
	for(sym <- inv[target]) {
		if (sym notin component) return true;
	}
	return false;
}

/* Create an empty production rule for the ending delimiters*/
set[Production] createEpsilonEndingRules(SymbolDelimiters symdels, set[Symbol] component, Graph[Symbol] graph) {
	result = {};
	for (key <- symdels) {
		if(isDirectlyReachableFrom(key, component, graph))
			result += prod(symdels[key], [], {});
	}
	return result;
}


/* For the given rule we check its type (everything should be \prod(...))
 * Then start finding non-terminals in current components
 * When you find one create a new rule from index max(0, previous elem in M + 1) up till and including the found non terminal
 * In the end add a last rule, closing the parsing of the given lhs, being lhs_end
 * return the new set of rules
 */  
set[Production] splitUpRule(Production rule, Grammar g, SymbolDelimiters symdels, set[Symbol] component) {
	set[Production] split = {};
	switch(rule) {
		case \prod(Symbol lhs, list[Symbol] rhs, _): {
			int index = 0;
			Symbol new_lhs = lhs;
			list[Symbol] new_rhs = [];
			set[Attr] new_attr = {};
			while (index < size(rhs)) {
				cur_sym = rhs[index];
				new_rhs += cur_sym;
				<isInComp, sym> = isSubSymbolInComponent(cur_sym, component);
				if (isInComp) {
					split += prod(new_lhs, new_rhs, new_attr);
					new_rhs = [];
					new_lhs = symdels[sym];
					new_attr = {};
				}
				index += 1;
			}
			if(label(str name, Symbol s) := lhs) lhs = s;
			split += prod(new_lhs, new_rhs + symdels[lhs], new_attr);
		} default: {
			throw error("found a rule that was not prod()");
		}
	}
	return split;
}

/* Simple mapping from a symbol to its closing symbol */
alias SymbolDelimiters = map[Symbol, Symbol];

set[Production] generateNewRules(Grammar g) {
	set[Production] rules_out = {};
	set[Production] rulesLeft = getRulesOfComp(g, {sym | sym <- g.rules});
	comps = grammar2strConnectedComponents(g);
	graph = grammar2graph(g);
	for (comp <- comps) {
		set[Production] rulesOfComp = getRulesOfComp(g, comp);
		if (shouldRulesChange(rulesOfComp, comp)) {
			rulesLeft -= rulesOfComp;
			//Create ending symbols for elements of M
			SymbolDelimiters delimiters = constructSymbolDelimiters(g, comp);	
			//Generate new rules for this component
			set[Production] newRules = {};
			newRules += createEpsilonEndingRules(delimiters, comp, graph);
			if(getOneFrom(g.starts) in comp) newRules += prod(delimiters[getOneFrom(g.starts)], [], {});
			for(r <- rulesOfComp) {
				set[Production] splicedRule = splitUpRule(r, g, delimiters, comp);
				newRules += splicedRule;
			} 
			rules_out += newRules;
		}
	}			
	return rules_out + rulesLeft;
}

/* Takes in a grammar and rebuilds it to a grammar which is stronglyRegular. This new grammar
 * Should accept a superset of the original gramma's language 
 * Based on a paper by Mohri and Nederhof
 */
Grammar toStronglyRegularGrammar(Grammar g) {
	Grammar redone = toPlainGrammar(g);
	assert(size(redone.starts) == 1);
	set[Production] rules_out = generateNewRules(redone);
	return grammar(g.starts, rules_out);
}
