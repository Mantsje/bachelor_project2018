module grammars::conflicts::inSingleTransition

import Grammar;

start syntax C
	= A
	;
	
syntax A
	= B "b"
	| D "d"
	;
	
syntax D
	= "a"
	| "b" "q"
	;

syntax B
	= "b" "c"
	;