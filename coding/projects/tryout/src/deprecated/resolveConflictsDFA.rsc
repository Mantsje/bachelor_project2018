module syntax_highlighting::resolveConflictsDFA

import Prelude;

import grammar2dfa::symbols::SymbolToString;
import grammar2dfa::automata::StateMachine;
import syntax_highlighting::aliases;
import syntax_highlighting::findTerminalsOfState;

set[StateLabel] getNextStateLabels(TokenPath path, map[Symbol, StateMachine] dfas) {
	set[StateLabel] labels = {};
	Token tok = path.token;
	StateLabel deepest_lab = last(path.stack);
	StateMachine deepest_dfa = dfas[deepest_lab.machine];

	State deepest_next_state;
	if(\eps() := tok) deepest_next_state = deepest_lab.state;
	else deepest_next_state = takeOneFrom(deepest_dfa.transitions[deepest_lab.state, tok])[0];
	//State deepest_next_state = takeOneFrom(deepest_dfa.transitions[deepest_lab.state, tok])[0];
	StateLabel deepest_next_lab = <deepest_lab.machine, deepest_next_state>;
	labels += deepest_next_lab;
	stack = path.stack[..-1];
	while(!isEmpty(stack)) {
		if(deepest_next_state in deepest_dfa.finalStates) {
			tok = deepest_lab.machine;
			deepest_lab = last(stack);
			deepest_dfa = dfas[deepest_lab.machine];
			deepest_next_state = takeOneFrom(deepest_dfa.transitions[deepest_lab.state, tok])[0];
			deepest_next_lab = <deepest_lab.machine, deepest_next_state>;
			labels += deepest_next_lab;
		} else break;
		stack = stack[..-1];
	}
	return labels;
}

set[TokenPath] findNextTerminalsOfPath(TokenPath path, map[Symbol, StateMachine] dfas) {
	set[TokenPath] outPaths = {};
	newLabels = getNextStateLabels(path, dfas);
	for(lab <- newLabels) {
		nextPaths = findTokenPathsOfState(dfas, lab.machine, lab.state);
		for(newp <- nextPaths) {
			int index = 0;
			while(domain(path.stack)[index] != head(newp.stack).machine) index += 1;
			outPaths += <(path.stack[..index] + newp.stack), newp.token>;	
		}
	}
	return outPaths;
}

map[TokenPath, set[TokenPath]] findNextTerminalsOfConflict(set[TokenPath] conflict, map[Symbol, StateMachine] dfas) {
	map[TokenPath, set[TokenPath]] newPaths = ();
	for(path <- conflict) {
		println("orig: <path>");
		newPaths[path] = findNextTerminalsOfPath(path, dfas);
		for(n <- newPaths[path]) println("new: <n>");
		println();
	}
	return newPaths;
}

map[TokenPath, set[TokenPath]] findNextTerminalsOfConflict(map[TokenPath, set[TokenPath]] conflict, map[Symbol, StateMachine] dfas) {
	map[TokenPath, set[TokenPath]] newPaths = ();
	for(key <- conflict) {
		for(path <- conflict[key]) {
			newPaths[key] = findNextTerminalsOfPath(path, dfas);
		}
	}
	return newPaths;
}

DeltaFunction removeOldTransitions(DeltaFunction delta, set[TokenPath] conflict, StateLabel cur_lab) {
	for(path <- conflict) {
		cursize = size(delta);
		State next_state;
		Token token;
		if(size(path.stack) > 1) {
			token = head(tail(path.stack)).machine;
			next_state = takeOneFrom(delta[cur_lab.state, token])[0];
		} else {
			token = path.token;
			next_state = takeOneFrom(delta[cur_lab.state, token])[0];
		}
		delta -= <cur_lab.state, token, next_state>;
		assert(size(delta) == cursize - 1);
	}
	return delta;
}

Transition makeLookaheadTransition(StateLabel cur_lab, list[Token] tokens, State next_state) {
	return <cur_lab.state, \conditional(\empty(), {\follow(\seq(tokens))}), next_state>;
}

tuple[set[set[TokenPath]], set[TokenPath]] getConflictsRecurse(set[TokenPath] next_paths, map[TokenPath, TokenPath] path_to_origin) {
	set[set[TokenPath]] conflicts = findConflicts(next_paths);
	set[TokenPath] non_conflicting_paths = next_paths - ({} | it + cset | cset <- conflicts);
	//Remaining conflicts all coming from one original transition are no conflicts, we know which way to go
	for(c <- conflicts) {
		if(isConflictInOneTransition(c, path_to_origin)) {
			conflicts -= {c};
			non_conflicting_paths += c;
		//If it eps it should be the end of the possible derivation. No more lookahead possible so we give up on trying to solve
		} else if(\eps() := takeOneFrom(c)[0].token) {
			conflicts -= {c};
			non_conflicting_paths += c;
		}
	}
	return <conflicts, non_conflicting_paths>;
}

DeltaFunction solveNewNonConflictingPaths(set[TokenPath] nonconf, map[TokenPath, TokenPath] path_to_origin, list[Token] tokenStack,
										  StateLabel cur_lab, StateMachine cur_dfa) {
	DeltaFunction new_transitions = {};
	//For each non-conflicting path
	for(p <- nonconf) {
		//original path
		orig_choice = path_to_origin[p];
		//grow token stack with new lookahead token
		new_tokenStack = tokenStack + p.token;
		//Original transition token of the original path. So if we're breaking up A -> B -> "a" "b" this becomes B
		Token subtok;
		if(size(orig_choice.stack) == 1) subtok = orig_choice.token;
		else subtok = head(tail(orig_choice.stack)).machine;
		//Introduce an extra state right before making the choice such that we have a point to jump to once we fixed the conflict
		State newsubstate = "<cur_lab.state>_CONF_<symbolToString(subtok)>";
		//This is a fixed conflict so add the transitions. The lookahead from original state to the newly intermediate state
		//And from the newly instroduced state to the next state which we would have originally reached if we had instantly taken this path
		new_transitions += makeLookaheadTransition(cur_lab, new_tokenStack, newsubstate);
		new_transitions += <newsubstate, subtok, takeOneFrom(cur_dfa.transitions[cur_lab.state, subtok])[0]>;
	}
	return new_transitions;
}


StateMachine fixOneConflict(set[TokenPath] conflict, StateLabel cur_lab, map[Symbol, StateMachine] dfas, list[Token] tokenStack) {
	dfa = dfas[cur_lab.machine];
	//printStateMachineForGenerator(dfa);
	DeltaFunction new_transitions = {};
	
	//Token stack we've had up till now, should become a parameter
	tokenStack += takeOneFrom(conflict)[0].token;
	//new_transitions += makeLookaheadTransition(cur_lab, tokenStack, new_state);
	
	//next paths mapped by original path in de original dfa original path -> set[new_path]
	map[TokenPath, set[TokenPath]] next_paths_map = findNextTerminalsOfConflict(conflict, dfas);
	//inverted version of the above
	map[set[TokenPath], TokenPath] inv_next_paths_sub = invertUnique(next_paths_map);
	map[TokenPath, TokenPath] inv_next_paths_map = (() | it + (p:inv_next_paths_sub[keyset] | p <- keyset) | keyset <- inv_next_paths_sub);
	//Just get a total set of paths and find their conflicts, does not care about which transition
	//TODO: care about which transition, use the 3 maps above for this, should not be too hard
	set[TokenPath] next_paths = ({} | it + next_paths_map[p] | p <- next_paths_map);
	
	<conflicts, non_conflicting_paths> = getConflictsRecurse(next_paths, inv_next_paths_map);
	new_transitions += solveNewNonConflictingPaths(non_conflicting_paths, inv_next_paths_map, tokenStack, cur_lab, dfa);
	
	//TODO: Recurse for the still conflicting paths
	
	println(conflict);
	//Remove the old transitions and add the new ones
	dfa.transitions = removeOldTransitions(dfa.transitions, conflict, cur_lab);
	dfa.transitions += new_transitions;

	//printStateMachineForGenerator(dfa);
	return dfa;
}

bool isConflictInOneTransition(set[TokenPath] conflict, map[TokenPath, TokenPath] path_to_origin) {
	an_orig_path = path_to_origin[takeOneFrom(conflict)[0]];
	check = true;
	for(path <- conflict) check = check && (an_orig_path == path_to_origin[path]);
	return check;
}

bool isConflictInOneTransition(set[TokenPath] conflict) {
	chosenstack = takeOneFrom(conflict)[0].stack;
	StateLabel transition;
	//Means this is a single terminal transition from the current state.
	//However it is a conflict, so the other paths are not through this token. 
	if(size(chosenstack) == 1) return false;
	else transition = head(tail(chosenstack));
	check = true;
	for(path <- conflict) {
		StateLabel cur_trans;
		if(size(path.stack) == 1) return false;
		else cur_trans = head(tail(path.stack));
		check = check && transition == cur_trans;
	}
	return check;
}

//Fix all conflicts and change te ContextMap in doing so
StateMachine fixMachine(set[set[TokenPath]] conflicts, StateLabel cur_lab, map[Symbol, StateMachine] dfas) {	
	dfa = dfas[cur_lab.machine];
	for(conflict <- conflicts) {
		if(isEpsConflict(conflict) || isConflictInOneTransition(conflict)) {
			continue;
		} else {
			dfa = fixOneConflict(conflict, cur_lab, dfas, []);
		}
	}
	return dfa;
}

//If it eps it should be the end of the possible derivation. No more lookahead possible so we give up on trying to solve
bool isEpsConflict(set[TokenPath] conflict)
	= (\eps() := takeOneFrom(conflict)[0].token);


map[Symbol, StateMachine] toConflictlessMachines(map[Symbol, StateMachine] dfas) {
	for (dfa_sym <- dfas) {
		dfa = dfas[dfa_sym];
		map[State, set[TokenPath]] tmap = ();
		for(state <- getStates(dfa)) {
			tmap[state] = findTokenPathsOfState(dfas, dfa_sym, state);		
			StateLabel cur_lab = <dfa_sym, state>;
			if(hasConflicts(tmap[state])) {
				set[set[TokenPath]] conflicts = findConflicts(tmap[state]);
				StateMachine fixed_dfa = fixMachine(conflicts, cur_lab, dfas);
				dfas[dfa_sym] = fixed_dfa;
			} 
		}
	}
	return dfas;
}