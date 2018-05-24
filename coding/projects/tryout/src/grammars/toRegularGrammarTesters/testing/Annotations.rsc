module grammars::expressions::testing::Annotations

/* Test for checking performance with annotations in the grammar ...
 *
 *
 */
 
 start syntax E
 	= @context="nice" Id
 	| @category="dingen" E "+" E
 	;
 	
lexical Id = @category="identifier" "a";