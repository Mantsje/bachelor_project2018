module grammar::RewriteRules

import Prelude;


//Creates a new symbol for new rule introduced by rewriting priority rules
Symbol makeNewSymbol(Symbol s, int index) {
	switch(s) {
		case \sort(str name) :{
			return sort(name + "_<index>");		
		} case \lex(str name): {
			return lex(name + "_<index>");
		} default: {
			throw error("non-exhaustive pattern match in constructSymbolDelimiters! <s>");
		}
	}
}

//Creates for one production rule a rewritten variant
Production rewritePrioritySingleRule(Production rule, Symbol original, Symbol newSym, Symbol lhs) {
	if (\prod(Symbol lhs_r, list[Symbol] rhs_r, set[Attr] attrs_r) := rule) {
		if(rhs_r[0] == original) rhs_r[0] = lhs;
		if(rhs_r[size(rhs_r)-1] == original) rhs_r[size(rhs_r)-1] = lhs;	
		return prod(lhs, rhs_r, attrs_r);
	}
	throw error("rule was not prod() <rule>");
}

set[Production] rebuildPriority(Symbol original, list[Production] l) {
	set[Production] rebuild = {};
	groups = reverse(l);
	int index = 1;
	Symbol lhs = original;
	for (gr <- groups) {
		Symbol newSym = makeNewSymbol(original, index);
		switch (gr) {
			case \choice(Symbol sym, set[Production] choices): {
				rebuild += {rewritePrioritySingleRule(rule, original, newSym, lhs) | rule <- choices};
			} /*case \prod(Symbol lhs_r, list[Symbol] rhs_r, set[Attr] attrs_r): {
				rebuild += rewritePrioritySingleRule(gr, original, newSym, lhs);
			}*/ default: {
				throw error("Non-Exhaustive pattern match in rebuildPriority() <gr>");
			}
		} 	
		if (index < size(groups)) rebuild += prod(lhs, [newSym], {});
		lhs = newSym;
		index += 1;
	}
	return rebuild;
}

set[Production] rewritePriority(Symbol s, list[Production] l) {
	rewritten_l = [rewriteRule(rule) | rule <- l];
	l = [\choice(s, p) | p <- rewritten_l];
	return rebuildPriority(s, l);
}

set[Production] rewriteAssoc(Symbol lhs, Associativity as, set[Production] rhss) {
	//strip assoc tags
	assert(size({rule | rule <- rhss, !(\prod(_, _, _) := rule )}) == 0);
	rhss = ({} | it + prod(lh, rh, {a | a <- attrs, !(\assoc(_) := a)}) | \prod(Symbol lh, list[Symbol] rh, set[Attr] attrs) <- rhss);
	return ({} | it + rewriteRule(rule) | rule <- rhss);
}

Symbol removeLabel(Symbol s) {
	if (\label(_, Symbol in_s) := s) return in_s;
	return s;
}

/* Pattern match and rewrite rules
 * Just removes labels and associativity
 * Rewrites priority to multiple rules such that it is kept
 */
set[Production] rewriteRule(Production p) {
	switch (p) {
		case \choice(Symbol sym, set[Production] choices): {
			return ({} | it + rewriteRule(r) | r <- choices);
		} case \prod(Symbol lhs_r, list[Symbol] rhs_r, set[Attr] attrs_r): {
			return {prod(removeLabel(lhs_r), [removeLabel(s) | s <- rhs_r], attrs_r)};
		} case \associativity(Symbol lhs, Associativity as, set[Production] rhss): {
			return rewriteAssoc(lhs, as, rhss);
		} case \priority(Symbol s, list[Production] l): {
			return rewritePriority(s, l);
		} default: {
			throw error("Non-Exhaustive pattern match in rewriteRule: <p>");
		}
	}
}

//Returns the set of new productions only using \prod
set[Production] getRewrittenRules(Grammar g) {
	set[Production] all_rules = {g.rules[sym] | sym <- g.rules};
	set[Production] new_rules = ({} | it + rewriteRule(p) | p <- all_rules);
	return new_rules;
}

//Returns the same as above, only as a map
rel[Symbol, Production] mapRewrittenRules(Grammar g) {
	set[Production] all_rules = {g.rules[sym] | sym <- g.rules};
	set[Production] new_rules = ({} | it + rewriteRule(p) | p <- all_rules);
	return ({} | it + <lh,p> | p:\prod(Symbol lh, _, _) <- new_rules);
}

//Rewrites grammars to a set of rules with only \prod(...)
// it removes unwanted rule types like choice and associativity and priority and rewrites them
Grammar rewriteGrammar(Grammar g) {
	set[Production] new_rules = getRewrittenRules(g);
	return grammar(g.starts, new_rules);
}
