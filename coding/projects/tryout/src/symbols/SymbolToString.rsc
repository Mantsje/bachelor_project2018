module symbols::SymbolToString

import Prelude;
import symbols::Epsilon;

str symbolToString(Symbol s) {
	if(\eps() := s) return "_eps";
	if(\empty() := s) return "_empty";
	if(\layouts(str name) := s) return name;
	str symbolStr = "<type(s, ())>";
	if (startsWith(symbolStr, "\"") && endsWith(symbolStr, "\"")) symbolStr = symbolStr[1..size(symbolStr) - 1];
	return symbolStr;
}

str symbolToAlnumString(Symbol s) {
	if(\eps() := s) return "_eps";
	str symbolStr = "<type(s, ())>";
	if(\layouts(str name) := s) return name;
	if (startsWith(symbolStr, "\"") && endsWith(symbolStr, "\"")) symbolStr = symbolStr[1..size(symbolStr) - 1];
	return replaceIllegalChars(symbolStr);
}

str toAlnumString(str input)
	= replaceIllegalChars(input);

str replaceIllegalChars(str input) {
	set[tuple[str, str]] illegal = {
								<"(", "PARO">, 
								<")", "PARC">, 
								<"[", "BRAO">,
								<"]", "BRAC">,
								<"{", "CURO">,
								<"}", "CURC">,
								<"+", "PLUS">, 
								<"-", "DASH">, 
								<"*", "STAR">, 
								<"/", "SLASH">, 
								<"\\", "BSLASH">, 
								<"?", "QMARK">, 
								<"|", "VBAR">,
								<"^", "SLINE">,
								<"$", "ELINE">,
								<"=", "EQUAL">, 
								<"!", "EXCL">, 
								<"\>", "GT">, 
								<"\<", "LT">, 
								<",", "COMMA">, 
								<";", "SEMI">,
								<"\'", "SQUOTE">, 
								<"\"", "DQUOTE">, 
								<"`", "BTICK">,
								<" ", "_">,
								<"\t", "TAB">,
								<"\n", "NWLINE">, 
								<"\r", "BACKR"> 
								};
	
	for(il <- illegal) input = replaceAll(input, il[0], il[1]);
	return input;
}