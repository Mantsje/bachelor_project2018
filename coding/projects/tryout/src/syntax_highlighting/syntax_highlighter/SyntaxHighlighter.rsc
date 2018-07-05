module syntax_highlighting::syntax_highlighter::SyntaxHighlighter

import Prelude;

//IDEA: Could ake different regexes for different editors.
data SHRegex
	= \str-regex(str regex)
	;

data SyntaxHighlighter
	= \highlighter(str name, set[str] extensions, set[SHvar] vars, map[str, Context] contexts)
	;

data SHvar
	= \shvar(str name, SHRegex regex);

data Context
	= \context(str name, Scope scope, set[Match] matches, set[Context] includes, bool includePrototype=true)
	| \main(Scope scope, set[Match] matches, set[Context] includes)
	| \prototype(Scope scope, set[Match] matches, set[Context] includes)
	;

data Scope 
	= \scope(str name)
	| \meta-scope(str name)
	| \null()
	;

data Action
	= \push(list[str] contexts)
	| \setact(list[str] contexts)
	| \pop()
	| \noact()
	;
	
data Match
	= \match(SHRegex regex, Scope scope, Action action)
	;
	
str SHRegexToString(SHRegex regex) {
	switch(regex) {
		case \str-regex(str str_regex): return str_regex;
		default : throw error("Non-Exhaustive pattern match");
	}
}

SyntaxHighlighter addDebuggerScopes(SyntaxHighlighter syn) {
	new_cons = ();
	for (conname <- syn.contexts) {
		con = syn.contexts[conname];
		if (\null() := con.scope)
			con.scope = \meta-scope(conname);
		new_cons[conname] = con;
	}
	return \highlighter(syn.name, syn.extensions, syn.vars, new_cons);
}

SyntaxHighlighter removeUnreachableContexts(SyntaxHighlighter syn) {
	set[Context] reachable = {};
	Context main = syn.contexts["main"];
	reachable += main;
	Context prototype;
	if("prototype" in syn.contexts) {
		prototype = syn.contexts["prototype"];	
		reachable += prototype;
	}
	solve(reachable) {
		for (c <- reachable) {
			for(m <- c.matches) {
				if(!(\pop() := m.action)) reachable += {syn.contexts[n] | n <- m.action.contexts};
			}
			reachable += c.includes;
		}
	}
	map[str,Context] contexts = ("main":main);
	reachable -= main;
	if("prototype" in syn.contexts) {
		reachable -= prototype;
		contexts += ("prototype":prototype);
	}
	contexts += (c.name:c | c <- reachable);
	return \highlighter(syn.name, syn.extensions, syn.vars, contexts);
}

//TODO: make dependent on which highlighter/editor we want to generate for
SHRegex stringToSHRegex(str input) {
	return \str-regex(input);
}