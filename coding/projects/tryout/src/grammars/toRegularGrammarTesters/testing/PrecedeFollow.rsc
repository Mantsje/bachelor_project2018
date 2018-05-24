module grammars::expressions::testing::PrecedeFollow

/* Test for checking performance under precede/follow restrictions in the grammar
 * 
 * string interpolation
 * Works for non changing rules of course
 * 
 */
 
 start syntax E
 	= E "+" E
  	| Id
 	; 
 	

lexical Id 
	= "a" !<< [a-z]+ !>> E
	//| E
 	//= [a-z]+
 	;