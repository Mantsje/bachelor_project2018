module grammars::toRegularGrammarTesters::testing::Labels

/* Test for checking performance when items have labels
 *
 * label types:
 * | ruleName: \rule
 * | A aName B cName c cName
 */
 
start syntax E
	= E lh "+" plus E rh
	//= E "+" E
	| rule_a: "a" 
	| rule_comb: "combo" comb 
	;
	