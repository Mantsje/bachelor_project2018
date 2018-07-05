module grammars::conflicts::noConflicts

import Grammar;

start syntax C
	= A
	| B
	;

syntax A 
	= "a"
	| "b"
	;
	
syntax B 
	= "c"
	| "d"
	; 