module syntax_highlighting::RewriteSymbolToRegex

import Grammar;
import IO;

import grammar2dfa::symbols::IsTerminal;
import syntax_highlighting::SublimeText::ProductionToSublimeRegex;

set[Production] rebuildRules(Symbol s, set[Production] rules) {
	set[Production] new_rules = {};
	set[Production] toChange = {};
	for(p:\prod(Symbol lh, list[Symbol] rhs, _) <- rules) {
		if(\empty() := lh || \layouts(_) := lh || rhs == []) new_rules += p;
		else if((true | it && isTerminal(sym) | sym <- rhs)) toChange += p;
		else new_rules += p;
	}
	if(toChange != {}) new_rules += prod(s, [lit(convertAllToSublimeRegex(toChange))], {});
	return new_rules;
}
