module grammar::StronglyRegularGrammar

import Prelude;

import graph::grammar2graph;
import grammar::RewriteRules;

/* Productions can be:
   = \cons(Symbol def, list[Symbol] symbols, list[Symbol] kwTypes, set[Attr] attributes)
   | \func(Symbol def, list[Symbol] symbols, list[Symbol] kwTypes, set[Attr] attributes)
x  | \choice(Symbol def, set[Production] alternatives)
   | \composition(Production lhs, Production rhs)
x  | prod(Symbol def, list[Symbol] symbols, set[Attr] attributes) 
  		A production rule from symbol to list of (non-)terminals
   | regular(Symbol def)
  		A regex
x  | error(Production prod, int dot)
  		Error in parse tree -> to be ignored
x  | skipped() 
  		Error recovery -> no business with either
  x = seen and/or should be covered by algorithm
*/

set[Production] getRulesOfComp(Grammar g, set[Symbol] component) {
	set[Production] rules_out = {};
	for(rule <- {g.rules[sym] | sym <- component}) {
		switch (rule) {
			case p:\prod(Symbol lhs, list[Symbol] rhs, set[Attr] attrs): {
				rules_out += p;
			} case \choice(Symbol lhs, set[Production] choices): {
				rules_out += choices;
			} default: {
				throw error("Non-Exhaustive pattern match in getRulesOfComp: <rule>");
			}
		}
	}
	return rules_out;
}

/* Find a rule in the rule set that is not right-linear, if so return true, else false
 * right now we don't break the loop because I want to check if there are cases that are not \prod
 * TODO: Fix this once done
 */
bool shouldRulesChange(set[Production] rules, set[Symbol] wrt) {
	bool result = false;
	for (r <- rules) {
		switch(r) {
			case \prod(Symbol lhs, list[Symbol] rhs, set[Attr] attrs): {
				//How many non-terminals in M are in r's rhs?
				int nonTermsInM = (0 | it + 1 | elem <- rhs, (elem in wrt) || ((\label(str name, Symbol s) := elem) && s in wrt));
				if (nonTermsInM == 1) {
					if (!(last(rhs) in wrt)) {
						result = true;
					}
				} else if (nonTermsInM != 0) {
					result = true;
				}
			} default: {
				throw error("found a rule that was not just \"\\prod()\" : <r>");
			}
		}
	}
	return result;
}

/* Create for all symbols in a set a closing symbol: symbol_end.
 * Check if it already exists, if so, throw an error
 */
SymbolDelimiters constructSymbolDelimiters(Grammar g, set[Symbol] symbols) {
	SymbolDelimiters result = ();
	for (sym <- symbols) {
		symType = type(sym, ());
		str closeName = "<symType>_end";
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
			} default: {
				throw error("non-exhaustive pattern match in constructSymbolDelimiters! <sym>");
			}
		}
	}
	return result;
}


/* Create an empty production rule for the ending delimiters*/
set[Production] createEpsilonEndingRules(SymbolDelimiters symdels) {
	result = {};
	for (key <- symdels) {
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
		case \prod(Symbol lhs, list[Symbol] rhs, set[Attr] attrs): {
			int index = 0;
			Symbol new_lhs = lhs;
			list[Symbol] new_rhs = [];
			set[Attr] new_attr = attrs;
			while (index < size(rhs)) {
				cur_sym = rhs[index];
				new_rhs += cur_sym;
				if ((\label(str name, Symbol s) := cur_sym) && s in component) {
					cur_sym = s;
				} if (cur_sym in component) {
					if(size(new_rhs) > 0 && \layouts(_) := new_rhs[0]) new_rhs = new_rhs[1..];
					split += prod(new_lhs, new_rhs, new_attr);
					new_rhs = [];
					new_lhs = symdels[cur_sym];
					new_attr = {};
				}
				index += 1;
			}
			if(size(new_rhs) > 0 && \layouts(_) := new_rhs[0]) new_rhs = new_rhs[1..];
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

/* TODO: Do not abandon all knowledge of attributes*/
set[Production] generateNewRules(Grammar g) {
	set[Production] rules_out = {};
	set[Production] rulesLeft = getRulesOfComp(g, {sym | sym <- g.rules});
	comps = grammar2strConnectedComponents(g);
	for (comp <- comps) {
		set[Production] rulesOfComp = getRulesOfComp(g, comp);
		if (shouldRulesChange(rulesOfComp, comp)) {
			rulesLeft -= rulesOfComp;
			//Create ending symbols for elements of M
			SymbolDelimiters delimiters = constructSymbolDelimiters(g, comp);	
			//Generate new rules for this component
			set[Production] newRules = {};
			newRules += createEpsilonEndingRules(delimiters);
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
	Grammar redone = rewriteGrammar(g);
	set[Production] rules_out = generateNewRules(redone);
	return grammar(g.starts, rules_out);
}
