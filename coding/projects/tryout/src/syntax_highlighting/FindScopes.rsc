module syntax_highlighting::FindScopes

import Prelude;

import grammar::rewrite_grammar::RewriteRules;
import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;

map[Symbol, Scope] findScopes(Grammar plainGrammar) {
	map[Symbol, Scope] result = ();
	set[Production] rules = getRewrittenRules(plainGrammar);
	for (\prod(_, rhs, attrs) <- rules) {
		for(t:\tag("Context"(str scopeList)) <- attrs) {
			list[str] scopes_str = parseScopeList(scopeList);
			list[Scope] scopes = toScopes(scopes_str, rhs);
			newpart = mapScopes(scopes, rhs);
			for(sym <- newpart) {
				if(sym in result && result[sym] != newpart[sym]) 
					throw error("Symbol <sym> already had a different scope assigned. You\'re assigning another one! This is not allowed, one scope per Symbol at most");
				result[sym] = newpart[sym];
			}
		}
	}
	println("\nAssigned scopes:");
	for(k <- result) println("\t<k> : <result[k]>");
	println();
	return result;
}


map[Symbol, Scope] mapScopes(list[Scope] scopes, list[Symbol] symbols) {
	map[Symbol, Scope] out = ();
	if (size(scopes) == size(symbols)) {
		int index = 0;
		for(sym <- symbols) { 
			/*if(!(\null() := scopes[index]))*/ out[sym] = scopes[index]; 
			index += 1; 
		}
	} else throw error("Something went wrong, got more or less scopes than symbols in mapScopes");
	return out;
}

//From stringlist to actual scopes. meta-scopes for NT's, scopes for terminals and nulls for layouts
list[Scope] toScopes(list[str] strs, list[Symbol] rhs) {
	if (size(strs) > size(rhs)) throw error("more scopes than symbols in rule! Symbols: <[type(s, ()) | s <- rhs]>");
	list[Scope] out = [];
	int index = 0;
	Symbol sym;
	for(sym <- rhs) {
		if (\layouts(_) := sym) { out += \null(); continue; }
		else if(index < size(strs))	{
			if (strs[index] == "null") out += \null();
			else out += \scope(strs[index]);
		} else out += \scope(last(strs));
		index += 1;
	}
	return out;
}

//Space separeted string to list of strings
list[str] parseScopeList(str lst) {
	return split(" ", lst);
}