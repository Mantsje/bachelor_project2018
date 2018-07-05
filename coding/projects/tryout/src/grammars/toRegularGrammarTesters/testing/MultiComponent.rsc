module grammars::toRegularGrammarTesters::testing::MultiComponent

/* Test for checking performance under multiple strongly connected components
 * Seems to work fine
 *
 * cases:
 *	Disconnected
 *  Connected
 */
 
 start syntax E
 	= "a" B
 	;
 	
 syntax B
 	= "b" E "e"
 	| "f"
 	| C
 	;
 	
syntax C
	= "c" D
	;

syntax D
	= C "d"
	| "g"
	;