module grammars::expressions::testing::Lexical

/* Test for checking performance with lexical elements instead of only syntax
 *
 * Might act a little weird if the lexicals have different 
 * currently: just make the extra non-terminal a lexical as well, and hope...
 * TODO: think about this, discuss this
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
	| Id
	| Lex
	;
	
lexical Id 
	= [a-z0-9A-Z_] !<< [a-zA-Z][a-zA-Z0-9_]* !>> [a-z0-9_A-Z];

lexical Lex
	= "b" F | "q";
