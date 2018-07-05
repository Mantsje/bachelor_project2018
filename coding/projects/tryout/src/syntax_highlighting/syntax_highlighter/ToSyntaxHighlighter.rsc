module syntax_highlighting::syntax_highlighter::ToSyntaxHighlighter

import Prelude;
import grammar2dfa::automata::StateMachine;

import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;
import syntax_highlighting::FindScopes;
import syntax_highlighting::ToContexts;
import syntax_highlighting::regexes::Main;

import grammar::rewrite_grammar::RewriteRules;
import symbols::SymbolToString;

set[Symbol] findLayoutSymbols(Grammar g) {
	layoutSyms = {};
	for (p:\prod(Symbol s, [_*, Symbol elem, _*],_) <- getRewrittenRules(g)) {
		if (s is layouts) layoutSyms += s;
		if (elem is layouts) layoutSyms += elem;
	}
	return layoutSyms;
}

map[str, Context] createPrototype(Grammar plain, map[str, Context] contexts, map[Symbol, StateMachine] dfas) {
	layoutSyms = findLayoutSymbols(plain);
	if(size(layoutSyms) > 1) throw error("Multiple layouts found, should not happen: <layoutSyms>");
	else if(size(layoutSyms) == 1) {
		layoutSym = takeOneFrom(layoutSyms)[0];
		set[Match] protoMatches;
		if(layoutSym in dfas) {		
			str layoutName = "<symbolToString(layoutSym)>_0";
			layoutContext = contexts[layoutName];
			protoMatches = {\match(lookaheadRegex(regex), \null(), \push([layoutName])) | c:\match(SHRegex regex, _, _) <- layoutContext.matches};
		} else if (layoutSym != \layouts("$default$")) {
			protoMatches = {\match(prod2regex(plain.rules[layoutSym], ()), \null(), \noact())};
		}
		Context prototypeContext = \prototype(\null(), protoMatches, {});
		contexts += ("prototype":prototypeContext);
	}
	return contexts;
}

map[Symbol, str] mapSimpleSymbols(Grammar g) {
	map[Symbol, str] regexMap = ();
	for (key <- g.rules) {
		if (key is keywords) regexMap[key] = prod2regex(g.rules[key], ()).regex;
	}
	return regexMap;
}


SyntaxHighlighter toSyntaxHighlighter(map[Symbol, StateMachine] dfas, Grammar plain, Symbol startSymbol, str name, set[str] file_extensions) {
	map[Symbol, Scope] scopes = findScopes(plain);
	map[Symbol, str] regexMap = mapSimpleSymbols(plain);
		
	<startContext, contexts> = toContexts(dfas, startSymbol, scopes, regexMap);
	Context mainContext = \main(\null(), {}, {startContext});
	contexts += ("main":mainContext);
	contexts = createPrototype(plain, contexts, dfas);

	SyntaxHighlighter hl = \highlighter(name, file_extensions, {}, contexts);
	hl = removeUnreachableContexts(hl);
	hl = addDebuggerScopes(hl); 
	return hl;
}