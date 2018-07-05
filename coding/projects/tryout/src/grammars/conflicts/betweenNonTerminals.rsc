module grammars::conflicts::betweenNonTerminals

import Grammar;

start syntax C
	= A
	| B
	;
	
syntax A
	= "a" "b"
	;

syntax B
	= "a" "c"
	;