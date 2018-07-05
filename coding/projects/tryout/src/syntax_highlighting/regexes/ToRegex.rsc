module syntax_highlighting::regexes::ToRegex

import Grammar;
import String;
import IO;

import syntax_highlighting::regexes::CharRanges;
import symbols::Epsilon;

//creates a regular expression in the form of either a prefix or postfix.
//We ignore except, since we threw out all labels
tuple[str, str] conditionToRegex(Condition con, map[Symbol, str] regmap) {
	str prefix = "";
	str postfix = "";
	switch(con) {
		case \follow(Symbol symbol): 		postfix = "(?=(<symbolToRegex(symbol, regmap)>))";
		case \not-follow(Symbol symbol): 	postfix = "(?!(<symbolToRegex(symbol, regmap)>))";
		case \precede(Symbol symbol): 		prefix  = "(?\<=(<symbolToRegex(symbol, regmap)>))";
		case \not-precede(Symbol symbol): 	prefix  = "(?\<!(<symbolToRegex(symbol, regmap)>))";
		case \delete(Symbol symbol):  		prefix  = "(?!(<symbolToRegex(symbol, regmap)>))";
		case \begin-of-line():  			prefix  = "^";
		case \end-of-line():  				postfix = "$";
		case \except(_):  					return <"","">;
		default: throw error("Non-Exhaustive pattern match, conditionToRegex: <con>");
	}
	return <prefix, postfix>;
}

str symbolToRegex(Symbol s, map[Symbol, str] regmap) {
	if (s in regmap) return regmap[s];
	if (isNonTerminalType(s)) println("Warning: Trying to convert non terminal symbol to regex!: <s>");
	switch(s) {
		case \eps():										return "";
		case \empty():										return "";
		case \layouts(_):									throw error("Got non-terminal \\layouts to regex"); 
		case \lex(_): 										throw error("Got non-terminal \\lex to regex"); 
		case \sort(_): 										throw error("Got non-terminal \\sort to regex"); 
		case \keywords(_): 									throw error("Got non-terminal \\keywords to regex");
		case \lit(str name):								return "<replaceIllegalChars(name)>";
		case \cilit(str name):								return "((?i)<replaceIllegalChars(name)>)";
		case \char-class(_):								return charRangesToString(s);
		case \opt(Symbol sym): 								return "(<symbolToRegex(sym, regmap)>)?";
		case \iter(Symbol sym): 							return "(<symbolToRegex(sym, regmap)>)+";
		case \iter-star(Symbol sym):						return "(<symbolToRegex(sym, regmap)>)*";
		case \iter-seps(Symbol sym, list[Symbol] seps): {
			str symregex = symbolToRegex(sym, regmap);
			str sepsregex = ("" | it + "(<symbolToRegex(sep, regmap)><symregex>)" | sep <- seps);
			str res = "<symregex>(<sepsregex><symregex>)*";
			return res;
		} case \iter-star-seps(Symbol sym, list[Symbol] seps): {
			str symregex = symbolToRegex(sym, regmap);
			str sepsregex = ("" | it + "(<symbolToRegex(sep, regmap)><symregex>)" | sep <- seps);
			str res = "(<symregex>(<sepsregex><symregex>)*)?";
			return res;
		} case \seq(list[Symbol] syms): 								
			return ("" | it + "(<symbolToRegex(sym, regmap)>)" | sym <- syms);
		case \alt(set[Symbol] alts): {
			str res = ("" | it + "(<symbolToRegex(sym, regmap)>)|" | sym <- alts);
			return res[..size(res)-1];
		} case \conditional(Symbol sym, set[Condition] conditions): {
			str symreg = symbolToRegex(sym, regmap);
			str pref = "", postf = "";
			for(con <- conditions) {
				<pre, post> = conditionToRegex(con, regmap);
				if(pref != "" && pre != "") println("Warning: symbol has multiple prefixes in regex conditional");
				if(postf != "" && post != "") println("Warning: symbol has multiple postfixes in regex conditional");
				pref += pre;
				postf += post;
			}
			return "<pref><symreg><postf>";
		} default: throw error("Non-Exhaustive pattern match isTerminal: <s>");
	}
}


str replaceIllegalChars(str input) {
	set[str] illegal = {
			"(" , ")" , "[" , "]", "{" , 
			"}" , "+" , "-" , "*", "/" , 
			"?" , "|" , "^" , "$", "=" , 
			"!" , "\>", "\<", ",", ";" , 
			"\'", "\"", "`" , " ", "\n", 
			"\r", "\t" };
	input = replaceAll(input, "\\", "\\\\");
	for(il <- illegal) input = replaceAll(input, il, "\\<il>");
	return input;
}