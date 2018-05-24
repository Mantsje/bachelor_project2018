module grammar2dfa::automata::NFA2DFA

import Prelude;

import grammar2dfa::automata::StateMachine;

/* Implementation of the traditional Powerset construction for generating a DFA from an NFA */

map[State, set[State]] epsClos;

set[State] epsilonClosureRecursive(set[State] states, StateMachine n, set[State] passed) {
	if (states == {}) return {};
	set[State] new_states = ({} | it + n.transitions[s, \eps()] | s <- states);		
	new_passed = passed + new_states;
	recurse = {};
	for(ns <- new_states, !(ns in passed)) recurse += epsilonClosureHelper(ns, n, new_passed);
	return states + new_states + recurse;
}
 
set[State] epsilonClosure(State s, StateMachine n)
	= epsilonClosureHelper(s, n, {});


set[State] epsilonClosureStateSet(set[State] ss, StateMachine n)
	= ({} | it + epsilonClosureHelper(s, n, {}) | s <- ss);


set[State] epsilonClosureHelper(State s, StateMachine n, set[State] passed) {
	if (s in epsClos) {
		return epsClos[s];
	}
	set[State] clos = epsilonClosureRecursive({s}, n, passed);
	epsClos[s] = clos;
	return clos;
}

bool isFinalStateSet(set[State] states, set[State] finalStates)
	= (false | it || (s in finalStates) | s <- states);

StateMachine NFA2DFA(StateMachine nfa) {
	map[State, set[State]] newMap = ();
	epsClos = newMap;
	
	map[set[State], str] new_states = ();
	
	set[State] final_states = {};
	DeltaFunction new_trans = {};
	str startStateName = "0";
	set[State] startState = epsilonClosure(nfa.startState, nfa);
	new_states[startState] = startStateName;
	if (isFinalStateSet(startState, nfa.finalStates)) final_states += new_states[startState];
	
	stateIndex = 1;
	set[set[State]] new_state_queue = {startState};
	
	while(!(isEmpty(new_state_queue))) {
		<cur_state, new_state_queue> = takeOneFrom(new_state_queue);
		rel[Token, State] reachable = ({} | it + nfa.transitions[state]| state <- cur_state);
		set[Token] alphabet = ({} | it + tr[0] | tr <- reachable, tr[0] != \eps());
		for (tok <- alphabet) {
			discovered_state = epsilonClosureStateSet(reachable[tok], nfa);		
			if(!(discovered_state in new_states)) {
				new_states[discovered_state] = "<stateIndex>";
				stateIndex += 1;
				new_state_queue += {discovered_state};	
				if (isFinalStateSet(discovered_state, nfa.finalStates)) final_states += new_states[discovered_state];
			}
			new_trans += <new_states[cur_state], tok, new_states[discovered_state]>;
		}
	}
	return \sm-dfa(new_trans, startStateName, final_states);
}