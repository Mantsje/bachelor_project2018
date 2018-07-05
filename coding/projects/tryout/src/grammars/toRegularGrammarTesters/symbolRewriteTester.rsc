module grammars::toRegularGrammarTesters::symbolRewriteTester

import Grammar;

start syntax A
	= B
	//| C*
	//| C?
	| D
	//| (B | C)
	//| {C ","}+
	//| {B "-\>"}*
	;
	
lexical D
	= (B C)
	;
	
lexical B
	= "b";

	
lexical C
	= "c";