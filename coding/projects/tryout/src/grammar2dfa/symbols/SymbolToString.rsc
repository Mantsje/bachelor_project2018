module grammar2dfa::symbols::SymbolToString

import Prelude;

str symbolToString(Symbol s) {
	if(\eps() := s) return "_eps";
	str symbolStr = "<type(s, ())>";
	if (startsWith(symbolStr, "\"") && endsWith(symbolStr, "\"")) symbolStr = symbolStr[1..size(symbolStr) - 1];
	return symbolStr;
}