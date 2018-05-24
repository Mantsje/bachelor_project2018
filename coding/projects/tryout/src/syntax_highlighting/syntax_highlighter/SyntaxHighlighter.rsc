module syntax_highlighting::syntax_highlighter::SyntaxHighlighter

import Prelude;
import grammar2dfa::automata::StateMachine;

//TODO: determine wheter we want custom SHregexes per editor, or do this distinction somewhere else
data SHRegex
	= \str-regex(str regex)
	;

data SyntaxHighlighter
	= \highlighter(str name, set[str] extensions, set[SHvar] vars, set[Context] contexts)
	;

data SHvar
	= \shvar(str name, SHRegex regex);

data Context
	= \context(str name, Scope scope, set[Match] matches, set[Context] includes)
	| \context-no-scope(str name, set[Match] matches, set[Context] includes)
	| \main(Scope scope, set[Match] matches, set[Context] includes)
	| \main-no-scope(set[Match] matches, set[Context] includes)
	| \prototype(Scope scope, set[Context] includes)
	;

data Scope 
	= \scope(str name)
	| \meta-scope(str name)
	;

data Action
	= \push(list[Context] contexts)
	| \setact(list[Context] contexts)
	| \pop()
	;
	
data Match
	= \match(SHRegex regex, Scope scope, Action action)
	| \match-no-scope(SHRegex regex, Action action)
	;
	
str SHRegexToString(SHRegex regex) {
	switch(regex) {
		case \str-regex(str str_regex): return str_regex;
		default : throw error("Non-Exhaustive pattern match");
	}
}

//TODO: make dependant on which highlighter/editor we want to generate for
SHRegex stringToSHRegex(str input) {
	return \str-regex(input);
}