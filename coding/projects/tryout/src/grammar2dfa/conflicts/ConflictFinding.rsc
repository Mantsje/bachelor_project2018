module grammar2dfa::conflicts::ConflictFinding

import Prelude;

import grammar2dfa::automata::StateMachine;

set[Token] firstDifTransitionsTrackPassed(StateMachine m, State s, set[Transition] except, map[Symbol, StateMachine] machines, set[Symbol] passed) {
	set[Token] toks = {};
	for(<tok, to> <- m.transitions[s]) {
		if(<s,tok,to> notin except) {
			toks += tok;
			if (tok in machines && tok notin passed) toks += firstTrackPassed(machines[tok], machines[tok].startState, machines, passed + tok);
		}
	}
	return toks;
}

set[Token] firstTrackPassed(StateMachine m, State s, map[Symbol, StateMachine] machines, set[Symbol] passed) {
	set[Token] toks = {};
	for(<tok,_> <- m.transitions[s]) {
		toks += tok;
		if (tok in machines && tok notin passed) toks += firstTrackPassed(machines[tok], machines[tok].startState, machines, passed + tok);
	}
	return toks;
}

set[Token] firstDifTransitions(StateMachine m, State s, set[Transition] except, map[Symbol, StateMachine] machines) {
	set[Token] toks = {};
	for(<tok, to> <- m.transitions[s]) {
		if(<s,tok,to> notin except) {
			toks += tok;
			if (tok in machines) toks += first(machines[tok], machines[tok].startState, machines);
		}
	}
	return toks;
}

set[Token] first(StateMachine m, State s, map[Symbol, StateMachine] machines) {
	set[Token] toks = {};
	for(<tok,_> <- m.transitions[s]) {
		toks += tok;
		if (tok in machines) toks += first(machines[tok], machines[tok].startState, machines);
	}
	return toks;
}

set[Transition] findConflicts(StateMachine m, Transition tr, map[Symbol, StateMachine] machines) {
	StateMachine other = machines[tr.token];
	set[Token] firstOfNT = first(other, other.startState, machines);
	set[Token] firstWithoutTr = firstDifTransitions(m, tr.from, {tr}, machines);
	if(!isEmpty(firstWithoutTr & firstOfNT)) return {tr};
	return {};
}

//Does not take the special symbols into account. like NT* or {NT, ","}+, should not exist at this point
set[Transition] findConflicts(map[Symbol, StateMachine] machines, StateMachine m, map[Symbol, set[Symbol]] componentMap) {
	compsum = ({} | it + componentMap[s] | s <- componentMap);
	nt_trans = {};
	for(tr:<from, tok, to> <- m.transitions) {
		if (tok in compsum) nt_trans += tr;
	}
	conflicts = {};
	for(tr <- nt_trans) conflicts += findConflicts(m, tr, machines);
	return conflicts;
}

map[Symbol, set[Transition]] findConflicts(map[Symbol, StateMachine] machines, set[set[Symbol]] components) {
	map[Symbol, set[Symbol]] componentMap = (s:({} | it + comp | comp <- components, s in comp) | s <- machines);
	out = ();
	for(sym <- machines) {
		out[sym] = findConflicts(machines, machines[sym], componentMap);
	}
	return out;
}