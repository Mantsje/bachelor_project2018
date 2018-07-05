Grammar toPlainGrammar(Grammar g, bool keepLayout=false) {
	set[Production] rules = getRewrittenRules(g);
	set[Production] new_rules = {};
	for (rule <- rules) new_rules += rewriteSymbolsInRule(rule);
	if(!keepLayout) new_rules = removeLayouts(new_rules);
	return grammar(g.starts, new_rules);
}