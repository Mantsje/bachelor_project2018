module syntax_highlighting::SublimeText::ProductionToSublimeRegex

import syntax_highlighting::SublimeText::SublimeRegex;

import Grammar;
import String;

import IO;

/* prods should only be of type \prod(_,_,_), is ensured by functions like RewriteRules in src::grammar::...*/

str convertAllToSublimeRegex(set[Production] prods) {
	str str_regex = "";
	for(p:\prod(Symbol lh, list[Symbol] rhs, _) <- prods) {
		str_regex += "<convertToSublimeRegex(lh, rhs)>|";
	}
	str_regex = substring(str_regex, 0, size(str_regex)-1);
	println(str_regex);
	SublimeRegex reg = stringToSublimeRegex(str_regex);
	return sublimeRegexToString(reg);
}

str convertToSublimeRegex(Symbol lh, list[Symbol] rhs)
	= convertRule(rhs);


str convertRule(list[Symbol] rh) {
	reg = "";
	for(r <- rh) reg += "<convertSymbol(r)>";
	return reg;
}

//TODO: add layout* everywhere when we're talking about syntax tokens and not when talking about lexicals
//Layout tokens are really still ignored now, this might pose a problem at some point
str convertSymbol(Symbol s) {
	switch (s) {
		//TODO: make layout better
		case \layouts(_):			return " ";
		case \sort(str n):			return "{{<n>}}";
		case \lex(str n):			return "{{<n>}}";
		case \keywords(str n):		return "{{<n>}}";
		case \lit(str n): 			return "<n>";
		case \cilit(str n): 		return "((?i)<n>)";
		case \char-class(_): 		return "<type(s, ())>";
		
		case \opt(Symbol opt_sym): 			return "<convertSymbol(opt_sym)>?";
		case \iter(Symbol iter_sym): 		return "<convertSymbol(iter_sym)>+"; 		
		case \iter-star(Symbol iter_sym): 	return "<convertSymbol(iter_sym)>*";	
		
		case \iter-seps(Symbol iter_sym, list[Symbol] seps): 
			return "<convertSymbol(iter_sym)>(<("" | it + "<convertSymbol(sep)> " | sep <- seps)><convertSymbol(iter_sym)>)*";
		case \iter-star-seps(Symbol iter_sym, list[Symbol] seps): 
			return "(<convertSymbol(iter_sym)>(<("" | it + "<convertSymbol(sep)> " | sep <- seps)><convertSymbol(iter_sym)>)*)?";
		case \alt(set[Symbol] alternatives): {
			reg = "<("" | it + "<convertSymbol(sym)>|" | sym <- alternatives)>";
			return "<substring(reg, 0, size(reg) - 1)>";
		} case \seq(list[Symbol] syms): 			
			return "<("" | it + "<convertSymbol(sym)> " | sym <- syms)>";		
		case \conditional(Symbol con_sym, set[Condition] conditions): {
			reg = "<convertSymbol(con_sym)>";
			for(con <- conditions) {
				<pref, post> = convertCondition(con);
				reg = "<pref> <reg> <post>";
			}
			return reg;
		}

		default: throw error("Non_exhaustive pattern match InSubSymbol: <s>");
	}
}

//TODO: look at delete symbol
tuple[str , str] convertCondition(Condition con) {
	str prefix = "";
	str postfix = "";
	switch(con) {
		case \follow(Symbol symbol): 		postfix += "?=<convertSymbol(symbol)>";
		case \not-follow(Symbol symbol): 	postfix += "?!<convertSymbol(symbol)>";
		case \precede(Symbol symbol): 		prefix += "?\<=<convertSymbol(symbol)>";
		case \not-precede(Symbol symbol): 	prefix += "?\<!<convertSymbol(symbol)>";
		case \begin-of-line():  			prefix += "^";
		case \end-of-line():  				postfix += "$";
		case \delete(Symbol symbol):  		prefix += "?!<convertSymbol(symbol)>";
		default: throw error("Non-Exhaustive pattern match, isTerminalCondition: <con>");
	}
	if (prefix != "") prefix = "(<prefix>)";
	if (postfix != "") postfix = "(<postfix>)";
	return <prefix, postfix>;
}
