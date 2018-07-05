module symbols::IsTerminal

import Grammar;
import symbols::Epsilon;

bool isTerminalCondition(Condition con) {
	switch(con) {
		case \follow(Symbol symbol): 		return isTerminal(symbol);
		case \not-follow(Symbol symbol): 	return isTerminal(symbol);
		case \precede(Symbol symbol): 		return isTerminal(symbol);
		case \not-precede(Symbol symbol): 	return isTerminal(symbol);
		case \delete(Symbol symbol):  		return isTerminal(symbol);
		case \begin-of-line():  			return true;
		case \end-of-line():  				return true;
		case \except(_):  					return true;
		default: throw error("Non-Exhaustive pattern match, isTerminalCondition: <con>");
	}
}

bool isTerminal(Symbol s) {
	switch(s) {
		case \start(Symbol inner):							return isTerminal(inner);
		case \eps():										return true;
		case \empty():										return true;
		case \label(_, sym):								return isTerminal(sym);
		case \layouts(_):									return false;
		case \lex(_): 										return false;
		case \sort(_): 										return false;
		case \keywords(_): 									return false;
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