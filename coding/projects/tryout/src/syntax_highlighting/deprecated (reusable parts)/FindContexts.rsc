module syntax_highlighting::FindContexts

import IO;
import Set;
import Grammar;
import List;
import Map;

import grammar2dfa::automata::DFA::Statistics;
import grammar2dfa::automata::Automaton;
import grammar2dfa::symbols::SymbolMap;


set[NamedTrans] getLocationsInDerivation(list[NamedTrans] deriv, NamedTrans cur, map[str, DFA] dfas) {
	set[NamedTrans] next_trs = getNamedTransitionsOfState(dfas[cur[0]], cur[0], cur[1][2]);
	//Is new state final state of machine? -> also add next state of upper machine
	if(cur[1][2] in dfas[cur[0]][2]) {
		new_deriv = pop(deriv)[1];
		ntran = top(new_deriv);
		next_trs += getLocationsInDerivation(new_deriv, ntran, dfas);
	}
	return next_trs;
}
			
			
void fixConflicts(map[str, set[list[NamedTrans]]] confls, map[str, DFA] dfas, map[str, Symbol] mapsym) {
	new_derivs = ();
	for (conf <- confls) {
		derivs = confls[conf];
		new_derivs[conf] = {};
		for (lst <- derivs) {
			NamedTrans ntran = top(lst);
			next_trns = getLocationsInDerivation(lst, ntran, dfas);
			new_steps = firstTerminalsOfTransitions(next_trns, dfas, mapsym);
			println(new_steps);
			new_derivs[conf] += new_steps;
		}
	}
	println();
	for (p <- new_derivs) {
		println("<p> : <new_derivs[p]>");
		confs = findConflicts(new_derivs[p]);
		println(confs);
	}
}

map[str, set[list[NamedTrans]]] findConflicts(set[list[NamedTrans]] derivs) {
	conflicts = ();
	map[list[NamedTrans], str] mapping = ();
	for (lst <- derivs) {
		str terminal = top(lst)[1][1];
		mapping += (lst:terminal);
	}
	inv = invert(mapping);
	return (key:inv[key] | key <- inv, size(inv[key]) > 1);
}

set[list[NamedTrans]] firstTerminalsOfTransition(NamedTrans trans, map[str, DFA] dfas, map[str, Symbol] mapsym) {
	<d_name, <state, token, nextState>> = trans;
	//Does token have its own dfa?
	if(!(token in mapsym)) return {[trans]};
	new_dfa = dfas[token];
	new_state = new_dfa[1];
	set[NamedTrans] new_transs = getNamedTransitionsOfState(new_dfa, token, new_state);
	return {deriv + [trans] | deriv <- firstTerminalsOfTransitions(new_transs, dfas, mapsym)};
}

//TODO: What if (part of this) generates empty lists? how to handle this
set[list[NamedTrans]] firstTerminalsOfTransitions(set[NamedTrans] transs, map[str, DFA] dfas, map[str, Symbol] mapsym) {
	res = {};
	for(trans <- transs) res += firstTerminalsOfTransition(trans, dfas, mapsym);
	return res;
}

void findContexts(map[str, DFA] dfas, SymbolMap symmap) {
	mapsym = invertUnique(symmap);
	for (d_name <- dfas) {
		namedTrans = getMultiTransitionStates(dfas, d_name);
		if(size(namedTrans) > 0) {
			set[list[NamedTrans]] derivs = firstTerminalsOfTransitions(namedTrans, dfas, mapsym);
			conflicts = findConflicts(derivs);
			fixConflicts(conflicts, dfas, mapsym);
		}
	}
	println();
	printInfoDFAs(dfas);
}