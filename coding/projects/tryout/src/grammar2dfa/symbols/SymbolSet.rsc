module grammar2dfa::symbols::SymbolSet

import Prelude;

/* Maps symbols to a string represetation of the name of the corresponding dfa */
//str mapSymbol(Symbol s) {
//	if(\empty() := s || \layouts(_) := s) return res;
//	str tokenName = "<type(s, ())>";
//	if (startsWith(tokenName, "\"") && endsWith(tokenName, "\"")) tokenName = tokenName[1..size(tokenName) - 1];
//	str prefix = "SM_";
//	//switch(s) {
//	//	case \cilit(_): { tokenName = replaceIllegalChars(tokenName); prefix = "LT_";}
//	//	case \lit(_): 	{ tokenName = replaceIllegalChars(tokenName); prefix = "LT_";}
//	//}
// 	tokenName = replaceIllegalChars(tokenName);
//	return "<prefix><tokenName>";
//}

//str replaceIllegalChars(str input) {
//		set[tuple[str, str]] illegal = {
//									<"(", "P_OP">, 
//									<")", "P_CL">, 
//									<"[", "B_OP">,
//									<"]", "B_CL">,
//									<"{", "C_OP">,
//									<"}", "C_CL">,
//									<"+", "PLUS">, 
//									<"-", "DASH">, 
//									<"*", "STAR">, 
//									<"/", "SLASH">, 
//									<"?", "QMARK">, 
//									<"|", "VBAR">,
//									<"^", "SLINE">,
//									<"$", "ELINE">,
//									<"=", "EQUAL">, 
//									<"!", "EXCL">, 
//									<"\>", "GT">, 
//									<"\<", "LT">, 
//									<",", "COMMA">, 
//									<";", "SEMI">,
//									<"\'", "SQUOTE">, 
//									<"\"", "DQUOTE">, 
//									<"`", "BTICK">,
//									<" ", "SPACE">,
//									<"\t", "TAB">,
//									<"\n", "NWLINE">, 
//									<"\r", "BACKR"> 
//									};
//	
//	for(il <- illegal) input = replaceAll(input, il[0], il[1]);
//	return input;
//}

set[Symbol] generateSymbolSet(set[Production] rules) {
	set[Symbol] syms = ( {} | it + lh + {i | i <- rh} | r <- rules, \prod(Symbol lh, list[Symbol] rh, _) := r, !(\start(_) := lh));
	set[Symbol] sym_queue = syms;
	while(!isEmpty(sym_queue)) {
		<sym, sym_queue> = takeOneFrom(sym_queue);
		new_syms = {};
		switch(sym) {
			case \layouts(_): 										syms -= sym;
			case \empty(): 											syms -= sym;
	      	case \opt(Symbol symbol): 								new_syms += symbol;
			case \iter(Symbol symbol): 								new_syms += symbol;
			case \iter-star(Symbol symbol): 						new_syms += symbol;
			case \iter-seps(Symbol symbol, list[Symbol] seps): 		new_syms += symbol + toSet(seps);
			case \iter-star-seps(Symbol symbol, list[Symbol] seps): new_syms += symbol + toSet(seps);
			case \alt(set[Symbol] alternatives): 					new_syms += alternatives;
			case \seq(list[Symbol] symbols): 						new_syms += toSet(symbols);
			case \char-class(_): 	continue;
			case \sort(_): 			continue;
			case \lex(_): 			continue;
			case \cilit(_): 		continue;
			case \lit(_): 			continue;
			case \keywords(_): 		continue;
			case \conditional(Symbol symbol, set[Condition] conditions): {
				new_syms += symbol; 
				new_syms += ({} | it + getSymbolFromCondition(con)| con <- conditions);
			} default: throw error("Non-Exhaustive pattern match in GenerateSymbolSet: <sym>");
		}
		sym_queue += new_syms;
		syms += new_syms;
	}
	//was used when we still wanted string naming of symbols
	//mapping =  (s:mapSymbol(s) | s <- syms);
	//assert(size(mapping) == size(syms));
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
		default: throw error("Non-Exhaustive pattern match, isTerminalCondition: <con>");
	}
}