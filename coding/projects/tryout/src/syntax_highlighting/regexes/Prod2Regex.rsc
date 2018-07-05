module syntax_highlighting::regexes::Prod2Regex

import Prelude;

import syntax_highlighting::regexes::ToRegex;

set[Production] getProds(Production p) {
	ps = {};
	switch (p) {
		case \choice(_, set[Production] choices): {
			return ({} | it + getProds(r) | r <- choices);
		} case \prod(_,_,_): {
			return {p};
		} default: {
			throw error("Non-Exhaustive pattern match in rewriteRule: <p>");
		}
	}
}

str strRegexAlts(set[str] alts) {
	str str_regex = ("" | it + reg + "|" | reg <- alts);
	return str_regex[..-1];
}


str prod2strregex(Production p, map[Symbol, str] regmap) {
	set[Production] ps = getProds(p);
	set[str] alts = {};
	for(\prod(Symbol lh, list[Symbol] rhs, _) <- ps) {
		alts += ("" | it + "(" + symbolToRegex(rh, regmap) + ")" | rh <- rhs);
	}
	return strRegexAlts(alts);
}