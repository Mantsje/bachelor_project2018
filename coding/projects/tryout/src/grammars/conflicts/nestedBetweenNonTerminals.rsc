module grammars::conflicts::nestedBetweenNonTerminals

import Grammar;

start syntax C
	= A
	| B
	;
	
syntax A
	= D "b"
	;

syntax B
	= D "c"
	;

syntax D
	= "a"
	;