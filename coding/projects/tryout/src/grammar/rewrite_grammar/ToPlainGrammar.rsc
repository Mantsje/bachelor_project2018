module grammar::rewrite_grammar::ToPlainGrammar

import Prelude;
import ParseTree;

import grammar::rewrite_grammar::RewriteRules;
import grammar::rewrite_grammar::RewriteSymbol;


set[Production] rewriteSymbolsInRule(rule:Production::\prod(Symbol lh, list[Symbol] rhs, set[Attr] attrs)) {
	set[Production] rules_out = {};
	<new_lh, _, extra_prods> = rewriteSymbol(lh);
	rules_out += extra_prods;
	new_rhs = [];
	//lhs are never a complicated symbol since they are user defined. There is no such thing as syntax A* = B* C*;
	for(rh <- rhs) {
		Symbol new_rh;
		<new_rh, _, extra_prods> = rewriteSymbol(rh);
		rules_out += extra_prods;
		new_rhs += new_rh;
	}
	rules_out += \prod(new_lh, new_rhs, attrs);
	return rules_out;
}

//Remove all layouts in the rules of the tokens that are not layouts
set[Production] removeLayouts(set[Production] rules) {
	for (p:\prod(Symbol lh, list[Symbol] rhs, set[Attr] attrs) <- rules) {
		//Do not remove the rules to which layouts can be rewritten, leave them, however they become unreachable by normal means
		if(!(\layouts(_) := lh)) {
			newrhs = [];
			for(rh <- rhs) {
				if (\layouts(_) := rh) continue;
				newrhs += rh;
			}
			rules = rules - p + \prod(lh, newrhs, attrs);
		}
	}	
	return rules;
}


/* Rewrites grammars to a set of rules with only \prod(...)
 * it removes unwanted rule types like choice and associativity and priority and rewrites them
 * Also rewrites symbols to a simpler form A* => A_STAR -> A A_STAR| \empty()
 * Aims to completely convert the grammar to a plain CFG with no extra features
 */
Grammar toPlainGrammar(Grammar g, bool keepLayout=false) {
	rules = getRewrittenRules(g);
	new_rules = {};
	for (rule <- rules) new_rules += rewriteSymbolsInRule(rule);
	if(!keepLayout) new_rules = removeLayouts(new_rules);
	return grammar(g.starts, new_rules);
}