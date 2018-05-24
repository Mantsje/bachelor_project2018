module grammars::expressions::testing::Layout

/* Test for checking performance under multiple strongly connected components
 *
 * Seems to work fine
 *
 */

start syntax E 
	= E "+" T
	| T
	;
	
syntax T
	= T "*" F
	| F
	;

syntax F
	= "(" E ")"
	| "a"
	;

layout White = [\t\n ]*;