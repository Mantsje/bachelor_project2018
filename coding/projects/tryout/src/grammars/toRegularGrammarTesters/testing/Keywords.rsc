module grammars::expressions::testing::Keywords

/* Test for checking performance when keywords are present
 * 
 *
 *
 */
 
 start syntax E
 	= E "+" E
 	| Id
 	;
 	
 syntax T 
 	= E "*" E;
 
 lexical Id 
 	= T [a-z]+ \ Standard 
 	| T T;
 
 keyword Standard = @category="keywords" ("for"|"if"|"else"|"while"|"do");
 