module grammars::expressions::testing::Assoc

/* Test for checking performance under associativity operators
 * Should not have an impact since it only does stuff to the AST, however could change underlying symbols
 *
 * assoc is an attribute
 * we could change the parse tree, however is this useful for syntax highlighting? -> think not
 * CURRENT: throw away associativity
 * TODO: get checked whether this is sufficient
 * TODO: make the attributes remain? -> rules get very broken. maybe not the best idea
 */
 
start syntax E
	= left E "+" E
	//= left (E "+" E | E "*" E)
	| "a" 
	;
	
