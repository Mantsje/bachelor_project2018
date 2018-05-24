module grammars::A

start syntax A
	= "a" B
	;

syntax B 
	= ("b"|"d")
	| A
	;

//syntax B 
//	= {C ","}+
//	;
//
//lexical C 
//	= A
//	| "int"
//	;