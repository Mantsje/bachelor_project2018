module grammars::expressions::Mohri

/* Produces expected 14 - different rules
 * No specialties, simple easy to read grammar
 *
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