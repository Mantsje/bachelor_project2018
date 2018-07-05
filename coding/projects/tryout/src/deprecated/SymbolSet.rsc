module grammar2dfa::symbols::SymbolSet

import Prelude;


//Finds all symbols in a set of productions. also recursively
set[Symbol] generateSymbolSet(set[Production] rules) {
	set[Symbol] syms = ( {} | it + lh + {i | i <- rh} | r <- rules, \prod(Symbol lh, list[Symbol] rh, _) := r, !(\start(_) := lh));
	set[Symbol] sym_queue = syms;
	while(!isEmpty(sym_queue)) {
		<sym, sym_queue> = takeOneFrom(sym_queue);
		new_syms = {};
		switch(sym) {
	      	case \opt(Symbol symbol): 								new_syms += symbol;
			case \iter(Symbol symbol): 								new_syms += symbol;
			case \iter-star(Symbol symbol): 						new_syms += symbol;
			case \iter-seps(Symbol symbol, list[Symbol] seps): 		new_syms += symbol + toSet(seps);
			case \iter-star-seps(Symbol symbol, list[Symbol] seps): new_syms += symbol + toSet(seps);
			case \alt(set[Symbol] alternatives): 					new_syms += alternatives;
			case \seq(list[Symbol] symbols): 						new_syms += toSet(symbols);
			case \empty(): 			syms -= sym;
			case \layouts(_): 		continue; //syms -= sym;
			case \sort(_): 			continue;
			case \lex(_): 			continue;
			case \keywords(_): 		continue;
			case \char-class(_): 	continue;
			case \cilit(_): 		continue;
			case \lit(_): 			continue;
			case \conditional(Symbol symbol, set[Condition] conditions): {
				new_syms += symbol; 
				new_syms += ({} | it + getSymbolFromCondition(con)| con <- conditions);
			} default: throw error("Non-Exhaustive pattern match in GenerateSymbolSet: <sym>");
		}
		sym_queue += new_syms;
		syms += new_syms;
	}
	return syms;
}

set[Symbol] getSymbolFromCondition(Condition con) {
	switch(con) {
		case \follow(Symbol symbol): 		return {symbol};
		case \not-follow(Symbol symbol): 	return {symbol};
		case \precede(Symbol symbol): 		return {symbol};
		case \not-precede(Symbol symbol): 	return {symbol};
		case \begin-of-line():  			return {};
		case \end-of-line():  				return {};
		case \delete(Symbol symbol):  		return {symbol};
		case \except(_):  					return {};
		default: throw error("Non-Exhaustive pattern match, isTerminalCondition: <con>");
	}
}