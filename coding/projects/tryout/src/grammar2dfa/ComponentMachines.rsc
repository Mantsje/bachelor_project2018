module grammar2dfa::ComponentMachines

import Prelude;

import grammar::strongly_regular_grammar::StronglyRegularGrammar;
import grammar::rewrite_grammar::RewriteRules;
import graph::Grammar2Graph;

import grammar2dfa::automata::StateMachine;
import symbols::Epsilon;

str FINAL_POSTFIX = "_FINAL";

State symbol2state(Symbol s) {
	return "<type(s, ())>";
}

str generateComponentName(set[Symbol] component) {
	out = ("" | it + symbol2state(s)| s <- component);
	out = replaceAll(out, "_end", "\'");
	out = replaceAll(out, "_", "");
	return out;
}

State generateFinalState(set[Symbol] component)
	= generateComponentName(component) + FINAL_POSTFIX;

DeltaFunction generateDeltaFunctionSymbol(set[Symbol] component, map[Symbol, set[Production]] sym_to_rules, Symbol cur) {
	State finalState = generateFinalState(component);
	DeltaFunction delta = {};
	int index = 0;
	for(\prod(Symbol lh, list[Symbol] rhs, _) <- sym_to_rules[cur]) {
		State cur_state = symbol2state(cur);
		for(tok <- rhs) {
			State next_state;
			if(tok in component) {
				next_state = symbol2state(tok);
				delta += <cur_state, \eps(), next_state>;
			} else {
				next_state = "term_<index>_<symbol2state(cur)>";
				index += 1;
				delta += <cur_state, tok, next_state>;
			}
			cur_state = next_state;
		}
		if(size(rhs) == 0) delta += <cur_state, \eps(), finalState>;
		else if(last(rhs) notin component) delta += <cur_state, \eps(), finalState>;
	}
	return delta;
}

DeltaFunction generateDeltaFunctionComponent(set[Symbol] component, map[Symbol, set[Production]] sym_to_rules) {
	DeltaFunction delta = {};
	for(sym <- component) delta += generateDeltaFunctionSymbol(component, sym_to_rules, sym);
	return delta;
}

StateMachine generateComponentMachine(set[Symbol] component, map[Symbol, set[Production]] sym_to_rules) {
	Symbol init = takeFirstFrom(component)[0];
	State startState = symbol2state(init);
	State finalState = generateFinalState(component);
	set[State] finalStates = {finalState};
	DeltaFunction delta = generateDeltaFunctionComponent(component, sym_to_rules);
	return \sm-nfa(delta, startState, finalStates);
}

map[Symbol, StateMachine] generateNFAsForComponent(set[Symbol] component, set[Production] rules) {
	map[Symbol, StateMachine] nfas = ();
	rel[Symbol, Production] prod_rel = {<lh,p> | p:\prod(Symbol lh, _, _) <- rules};
	map[Symbol, set[Production]] sym_to_rules = (lh:{} | <lh,p> <- prod_rel);
	for(<lh,p> <- prod_rel) sym_to_rules[lh] += p;
	StateMachine machine = generateComponentMachine(component, sym_to_rules);
	for(sym <- component) nfas[sym] = \sm-nfa(machine.transitions, symbol2state(sym), machine.finalStates);
	return nfas;
}

map[Symbol, StateMachine] generateNFAsForComponents(set[set[Symbol]] components, set[Production] all_rules) {
	map[Symbol, StateMachine] nfas = ();
	for(comp <- components) {
		assoc_rules = {p | p:\prod(Symbol lh, _, _) <- all_rules, lh in comp};
		nfas += generateNFAsForComponent(comp, assoc_rules);
	}
	return nfas;
}


/* *********** *********** *********** Main functions *********** *********** *********** */

//Rewrites the grammar, gets a set of production rules and the set of connected components
//After this the grammar is no longer needed. It also returns the starting symbol
tuple[Symbol, set[Production]] preprocessGrammar(Grammar g) {	
	assert(size(g.starts) == 1);
	startSymbol = takeOneFrom(g.starts)[0];
	set[Production] grammar_rules = getRewrittenRules(g);
	return <startSymbol, grammar_rules>;
}

map[Symbol, StateMachine] generateComponentNFAs(Grammar stronglyRegular, set[set[Symbol]] str_regular_comps) {
	<startSymbol, rules> = preprocessGrammar(stronglyRegular);
	map[Symbol, StateMachine] component_nfas = generateNFAsForComponents(str_regular_comps, rules);
	return component_nfas;
}
