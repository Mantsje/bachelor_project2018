module grammars::toRegularGrammarTesters::testing::Priority

/* Test for checking performance under priority operators in the grammar
 *
 * How does this affect things?
 * We choose to parse something else
 	- Can we rewrite this with an algorithm, always?
 * IDEA: rewrite all rules then go again?
 * Do we care? we still accept the language
 */
 
 start syntax E 
 	= "a"
 	| "(" E ")"
 	> E "*" E
 	> E "+" E
 	;
