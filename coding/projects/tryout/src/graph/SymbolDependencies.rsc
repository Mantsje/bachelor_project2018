module graph::SymbolDependencies

import Grammar;

set[Symbol] getDeepestSymbols(Symbol target) {
	switch(target) {
		case \sort(_):				return {target};
		case \lex(_):				return {target};
		case \keywords(_):			return {target};
		case \lit(_): 				return {target};
		case \cilit(_): 			return {target};
		case \char-class(_): 		return {target};
		case \layouts(_): 			return {target};
		case \empty(): 				return {target};
		case \label(_, Symbol s): 	return getDeepestSymbols(s);
		
		case \opt(Symbol opt_sym): 			return getDeepestSymbols(opt_sym);
		case \iter(Symbol iter_sym): 		return getDeepestSymbols(iter_sym); 
		case \iter-star(Symbol iter_sym): 	return getDeepestSymbols(iter_sym);
		
		case \iter-seps(Symbol s, list[Symbol] seps): 		return getDeepestSymbols(s) + ({} | it + getDeepestSymbols(sep) | sep <- seps);
		case \iter-star-seps(Symbol s, list[Symbol] seps): 	return getDeepestSymbols(s) + ({} | it + getDeepestSymbols(sep) | sep <- seps);
		
		case \alt(set[Symbol] alternatives):return ({} | it + getDeepestSymbols(alter) | alter <- alternatives);
		case \seq(list[Symbol] syms):  		return ({} | it + getDeepestSymbols(sym) | sym <- syms);
			
		//We just don't check the conditions
		case \conditional(Symbol s, set[Condition] conditions):
			return getDeepestSymbols(s);
		
		default: throw error("Non_exhaustive pattern match getDeepestSymbol: <target>");
	}
}	