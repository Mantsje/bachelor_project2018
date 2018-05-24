module grammar2dfa::Grammar2Automaton

import Prelude;

import grammar::StronglyRegularGrammar;
import grammar::RewriteRules;
import graph::grammar2graph;

import grammar2dfa::Symbol2NFA;
import grammar2dfa::automata::NFA2DFA;
import grammar2dfa::automata::StateMap;
import grammar2dfa::automata::StateMachine;
import grammar2dfa::symbols::SymbolSet;
import grammar2dfa::symbols::InSubSymbol;

import grammar2dfa::symbols::IsTerminal;


/* Per Symbol create an NFA with:
 * starting state
 * epsilon trans to all alternatives
 * per alternative a sub NFA having:
 * pre-state and post-state
 * N states inbetween
 * parsing/advancing a state means: run through NFA of non-terminal symbol or parse literals
*/


/* *********** *********** *********** Productions2NFA functions *********** *********** *********** */

StateMachine NFAForNoRuleSymbol(State startState, State endState, Symbol target) 
	= NFAForSymbol(startState, endState, target);
 
 
//TODO: check what to do with layouts here as well
DeltaFunction createNonTerminalDelta(set[Production] rules, Symbol target, State startState, State endState) {
	DeltaFunction trans = {}; 
	int index = 0;
	for (\prod(_, list[Symbol] rh, set[Attr] attrs) <- rules) {
		State curState = startState;
		int subIndex = 1;
		for (sym <- rh) {
			if(\layouts(_) := sym) continue;
			nextState = "in<index>_<subIndex>_<tokenToString(target)>";
			trans += <curState, sym, nextState>;
			subIndex += 1;
			curState = nextState;
		}			
		trans += <curState, \eps(), endState>;
		index += 1;	
	}
	return trans;
}

/* Generate an NFA for a set of associated rules where target == lhs.
 * For recursive symbols just state their name as transition
 * If there are no rules associated generate a "special" NFA.
 */
StateMachine toNFA(set[Production] assoc_rules, Symbol target) {
	State startState = "start_<tokenToString(target)>"; 
	State endState = "final_<tokenToString(target)>"; 
	set[State] finalStates = {endState};
	DeltaFunction trans = {};
	if (size(assoc_rules) > 0 ) {
		trans = createNonTerminalDelta(assoc_rules, target, startState, endState);
	} else {
		return NFAForNoRuleSymbol(startState, endState, target);
	}
	return \sm-nfa(trans, startState, finalStates);
}

/* For al symbols in the symbolMap generate an NFA parsing this symbol. 
 * TODO: look at layouts here
 */
map[Symbol, StateMachine] toNFAs(set[Symbol] symset, set[Production] all_rules) {
	map[Symbol, StateMachine] nfas = ();
	for(sym <- symset) {
		if(\layouts(_) := sym || \empty() := sym || \eps() := sym) continue;
		set[Production]	assoc_rules = {r | r:\prod(Symbol lh, _, _) <- all_rules, lh == sym};
		StateMachine nfa = toNFA(assoc_rules, sym);
		nfas[sym] = nfa;
	}
	return nfas;
}


/* *********** *********** *********** StronglyConnectedComponent functions *********** *********** *********** */


/* Rewrites one nfa such that it does not contain single transitions describing the parsing of a nonTerminal
 * instead this one gets replaced by the actual automaton created to parse said nonTerminal.
 * recursion with the same component/nfa is not possible here, so if the same machine occurs again its being renamed
 */
StateMachine rewriteAutomaton(StateMachine nfa, map[Symbol, StateMachine] comp_nfas, map[Symbol, StateMachine] symbol_nfas, StateMap statemap, str prefix) {
	DeltaFunction new_delta = {};
	for(tr <- nfa.transitions) {
		Token tok = tr[1];
		if (tok in statemap) {
			str newPrefix = prefix + tr[0] + "__";
			if (tok in comp_nfas) {		
				new_delta += rewriteAutomaton(comp_nfas[tok], comp_nfas, symbol_nfas, statemap, newPrefix).transitions;
			} else {
				//assert(isTerminal(tok));
				set[Transition] trs = symbol_nfas[tok].transitions;
				for(sub_tr <- trs) {
					new_delta +=  <newPrefix + sub_tr[0], sub_tr[1], newPrefix + sub_tr[2]>;
				}
			}
			new_delta += <prefix + tr[0], \eps(), newPrefix + statemap[tok][0]>;
			new_delta += <newPrefix + statemap[tok][1], \eps(), prefix + tr[2]>;
		} else {
			new_delta += <prefix + tr[0], tr[1], prefix + tr[2]>;
		}
	}
	return \sm-nfa(new_delta, prefix + nfa.startState, {prefix + s | s <- nfa.finalStates});
}

/* Does the same as the function above, but leaves rules that are not connected to this component untouched 
 * It also does not rename transitions, because recursion should be possible within a connected component*/
StateMachine rewriteAutomatonForComponent(StateMachine nfa, map[Symbol, StateMachine] nfas, StateMap statemap, set[StateMachine] passed, set[Token] comp) {
	if (nfa in passed) return \sm-nfa({}, "", {});
	DeltaFunction new_delta = {};
	for(tr <- nfa.transitions) {
		Token tok = tr[1];
		if (tok in statemap && (tok in comp || inSubSymbol(tok, comp))) {
			new_delta += rewriteAutomatonForComponent(nfas[tok], nfas, statemap, passed + nfa, comp).transitions;
			new_delta += <tr[0], \eps(), statemap[tok][0]>;
			new_delta += <statemap[tok][1], \eps(), tr[2]>;
		} else {
			new_delta += tr;
		}
	}
	return \sm-nfa(new_delta, nfa.startState, nfa.finalStates);
}

/* Flow:
 * For each component, generate an nfa
 * then for every element of the component, set this nfa to be its component
*/
map[Symbol, StateMachine] generateNFAPerComponent(map[Symbol, StateMachine] nfas, StateMap statemap, set[Symbol] symset, Symbol startSym, set[set[Token]] components) {
	map[Symbol, StateMachine] new_nfas = ();
	for (comp <- components) {
		chosen = takeOneFrom(comp)[0];
		StateMachine start_nfa = nfas[chosen];
		if (startSym in comp) start_nfa = nfas[startSym];
		StateMachine merged = rewriteAutomatonForComponent(start_nfa, nfas, statemap, {}, comp);	
		for (sym <- comp) new_nfas[sym] = merged;
	}
	return new_nfas;
}

/* get components of graph
 * for each component, generate an NFA
 * combine all these automata into the final one
 * return the dfa version of our final_nfa
 */
StateMachine mergeNFAs2DFA(map[Symbol, StateMachine] symbol_nfas, set[Symbol] symset, StateMap statemap, Symbol startSymbol, set[set[Token]] comps) {
	map[Symbol, StateMachine] component_nfas = generateNFAPerComponent(symbol_nfas, statemap, symset, startSymbol, comps);
	final_nfa = rewriteAutomaton(component_nfas[startSymbol], component_nfas, symbol_nfas, statemap, "");
	//printStateMachineForGenerator(final_nfa);
	println("number of transitions in final nfa: <size(final_nfa.transitions)>");
	println("number of states in final nfa: <size(getStates(final_nfa))>");
	return NFA2DFA(final_nfa);
}


/* *********** *********** *********** Main functions *********** *********** *********** */

//Rewrites the grammar, gets a set of production rules and the set of connected components
//After this the grammar is no longer needed. It also returns the starting symbol
tuple[Symbol, set[Production], set[set[Symbol]]] preprocessGrammar(Grammar g) {
	Grammar converted = toStronglyRegularGrammar(g);
	
	assert(size(converted.starts) == 1);
	startSymbol = takeOneFrom(converted.starts)[0];
	
	set[Production] grammar_rules = getRewrittenRules(converted);
	
	set[set[Token]] comps = grammar2strConnectedComponents(converted);
	return <startSymbol, grammar_rules, comps>;
}

map[Symbol, StateMachine] generateNFAPerSymbol(set[Symbol] symset, set[Production] rules) 
	= toNFAs(symset, rules);	

map[Symbol, StateMachine] generateNFAPerSymbol(Grammar g) {
	<startSymbol, rules, comps> = preprocessGrammar(g);
	set[Symbol] symset = generateSymbolSet(rules);
	return toNFAs(symset, rules);
}

map[Symbol, StateMachine] generateComponentNFAs(Grammar g) {
	<startSymbol, rules, comps> = preprocessGrammar(g);
	set[Symbol] symset = generateSymbolSet(rules);
	StateMap statemap = generateStateMap(symset);
	map[Symbol, StateMachine] symbol_nfas = generateNFAPerSymbol(symset, rules);
	map[Symbol, StateMachine] component_nfas = generateNFAPerComponent(symbol_nfas, statemap, symset, startSymbol, comps);
	return component_nfas;
}

map[Symbol, StateMachine] generateDFAPerSymbol(set[Symbol] symset, set[Production] rules) {
	map[Symbol, StateMachine] symbol_nfas = generateNFAPerSymbol(symset, rules); 
	return (n:NFA2DFA(symbol_nfas[n]) | n <- symbol_nfas);
}

map[Symbol, StateMachine] generateDFAPerSymbol(Grammar g) {
	<startSymbol, rules, comps> = preprocessGrammar(g);
	set[Symbol] symset = generateSymbolSet(rules);
	map[Symbol, StateMachine] symbol_nfas = generateNFAPerSymbol(symset, rules); 
	return (n:NFA2DFA(symbol_nfas[n]) | n <- symbol_nfas);
}

map[Symbol, StateMachine] generateComponentDFAs(Grammar g) {
	map[Symbol, StateMachine] comp_nfas = generateComponentNFAs(g); 
	return (n:NFA2DFA(comp_nfas[n]) | n <- comp_nfas);
}

StateMachine generateSuperDFA(Grammar g) {
	<startSymbol, rules, comps> = preprocessGrammar(g);
	set[Symbol] symset = generateSymbolSet(rules);
	StateMap statemap = generateStateMap(symset);
	map[Symbol, StateMachine] symbol_nfas = generateNFAPerSymbol(symset, rules);		
	StateMachine final_dfa = mergeNFAs2DFA(symbol_nfas, symset, statemap, startSymbol, comps);
	return final_dfa;
}

/* *********** *********** *********** *********** *********** *********** *********** */