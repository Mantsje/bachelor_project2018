module grammars::expressions::testing::MultiComponent

/* Test for checking performance under multiple strongly connected components
 * Seems to work fine
 *
 * cases:
 *	Disconnected
 *  Connected
 */
 
 start syntax A
 	= "a" B
 	;
 	
 syntax B
 	= "b" A "e"
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