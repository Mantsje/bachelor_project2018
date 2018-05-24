module grammar2dfa::symbols::IsTerminal

import Grammar;

bool isTerminalCondition(Condition con) {
	switch(con) {
		case \follow(Symbol symbol): 		return isTerminal(symbol);
		case \not-follow(Symbol symbol): 	return isTerminal(symbol);
		case \precede(Symbol symbol): 		return isTerminal(symbol);
		case \not-precede(Symbol symbol): 	return isTerminal(symbol);
		case \delete(Symbol symbol):  		return isTerminal(symbol);
		case \begin-of-line():  			return true;
		case \end-of-line():  				return true;
		default: throw error("Non-Exhaustive pattern match, isTerminalCondition: <con>");
	}
}

bool isTerminal(Symbol s) {
	switch(s) {
		case \layouts(_):									return true;
		case \lex(_): 										return false;	//TODO: Think about checking with production rules
		case \sort(_): 										return false;	//TODO: Think about checking with production rules
		case \keywords(_): 									return false;	//TODO: Think about checking with production rules
		case \lit(_):										return true;
		case \cilit(_):										return true;
		case \char-class(_):								return true;
		case \opt(Symbol sym): 								return isTerminal(sym);
		case \iter(Symbol sym): 							return isTerminal(sym);
		case \iter-star(Symbol sym):						return isTerminal(sym);
		case \iter-seps(Symbol sym, list[Symbol] seps): 	return (true | it && isTerminal(s) | s <- seps) && isTerminal(sym);
		case \iter-star-seps(Symbol sym, list[Symbol] seps):return (true | it && isTerminal(s) | s <- seps) && isTerminal(sym);
		case \seq(list[Symbol] syms): 						return (true | it && isTerminal(sym) | sym <- syms);
		case \alt(set[Symbol] alternatives): 				return (true | it && isTerminal(sym) | sym <- alternatives);
		case \conditional(Symbol sym, set[Condition] conditions): 
			return (true | it && isTerminalCondition(con) | con <- conditions) && isTerminal(sym);
		default: throw error("Non-Exhaustive pattern match isTerminal: <s>");
	}
}