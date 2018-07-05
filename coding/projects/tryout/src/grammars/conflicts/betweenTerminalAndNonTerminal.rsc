module grammars::conflicts::betweenTerminalAndNonTerminal

import Grammar;

start syntax C
	= "a" "b"
	| A
	;

syntax A
	= "a" "b"
	;