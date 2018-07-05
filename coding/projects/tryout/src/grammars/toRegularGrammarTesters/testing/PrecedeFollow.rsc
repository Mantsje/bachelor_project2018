module grammars::toRegularGrammarTesters::testing::PrecedeFollow

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
	= [a-z] !<< B !>> [a-z]
	//| E
 	//= [a-z]+
 	;
 
syntax B
	= E
	| "42"
	;