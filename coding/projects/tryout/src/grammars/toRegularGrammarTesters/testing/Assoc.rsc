module grammars::toRegularGrammarTesters::testing::Assoc

/* Test for checking performance under associativity operators
 * Should not have an impact since it only does stuff to the AST, however could change underlying symbols
 *
 * assoc is an attribute
 * we could change the parse tree, however is this useful for syntax highlighting? -> think not
 */
 
start syntax E
	= left E "+" E
	//= left (E "+" E | E "*" E)
	| "a" 
	;
	
