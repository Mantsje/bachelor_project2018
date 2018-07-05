module grammars::conflicts::betweenTerminalNonTerminalFinal

import Grammar;

start syntax C
	= "a" "b"
	| A
	;

syntax A
	= "a" D
	;

syntax D
	= "d"
	| "b"
	|
	;
