module grammar2dfa::conflicts::ConflictSolving

import Prelude;

import grammar2dfa::automata::StateMachine;
import grammar2dfa::automata::NFA2DFA;
import grammar2dfa::ComponentMachines;
import grammar2dfa::conflicts::ConflictFinding;
import grammar2dfa::conflicts::ComponentTree;
import symbols::Epsilon;

  
/* Get a tree with the components and their dependencies, all the machines and the components
 * map all symbols to their respective component
 * for each symbol in the root-component: solve the conflicts
 */
int cnt = 0;
map[Symbol, StateMachine] solveAllConflicts(NTree[set[Symbol]] tree, map[Symbol, StateMachine] machines,
										set[set[Symbol]] components) {
	map[Symbol, set[Symbol]] componentMap = (s:({} | it + comp | comp <- components, s in comp) | s <- machines);
	solved = {};
	cnt = 0;
	for(sym <- tree.root) {
		if(sym notin solved) 
			<machines, solved> = solveConflicts(tree, machines, sym, solved, componentMap);
	}			
	return machines;
}

/* First solve all conflicts in the children of the current symbol's component
 * Find all conflicting transitions in the current machine
 * while there are still conflicts:
 * 		substitute the machine that conflicts
 *		Make a dfa of the new nfa 
 *		find all conflicts again
 * replace the original machine in the machinemap with the new conflictless machine
 */
tuple[map[Symbol, StateMachine], set[Symbol]] solveConflicts(
										NTree[set[Symbol]] tree, map[Symbol, StateMachine] machines,
										Symbol current, set[Symbol] solved, map[Symbol, set[Symbol]] componentMap) {
	println("\t\t<cnt>/<size(machines)>: <current>");
	num_states_before = size(getStates(machines[current]));
	cnt += 1;
	
	for (child_comp <- tree.mapping[componentMap[current]]) {
		for(sym <- child_comp) {
			if (sym notin solved) 
				<machines, solved> = solveConflicts(tree, machines, sym, solved, componentMap);
		}
	}
	StateMachine curMachine = machines[current];
	set[Transition] conflicting_trans = findConflicts(machines, curMachine, componentMap);
	ind = 0;
	while(!isEmpty(conflicting_trans)) {
		println(current);
		println("working on <current>, currently with <size(conflicting_trans)> conflicts");
		for (conflict <- conflicting_trans) {
			curMachine = substituteTransition(current, curMachine, conflict, machines);	
		}
		println("pre-nfa2dfa: current number of states: <size(getStates(curMachine))>");
		curMachine = NFA2DFA(curMachine);
		println("past nfa2dfa");
		conflicting_trans = findConflicts(machines, curMachine, componentMap);
		println("past finding new conficts");
		ind += 1;
	}
	machines[current] = curMachine;
	return <machines, solved + {current}>;
}

/* replace all states with a certain prefix. prevents duplicate statenames in the nested machine */
StateMachine prefixStates(str prefix, StateMachine m) {
	m.startState = prefix + m.startState;
	set[State] newFinal = {};
	for(fs <- m.finalStates) newFinal += prefix + fs;
	m.finalStates = newFinal;
	DeltaFunction delta = {};
	for(tr <- m.transitions) delta += <prefix + tr.from, tr.token, prefix + tr.to>;
	m.transitions = delta;
	return m;
}

/* replaces one transition that has a NT on the arc 
* with the given machine with epsilon transitions 
* to and from this machine from the old state to the next state
*/
StateMachine substituteTransition(Symbol machine_sym, StateMachine m, Transition tr, map[Symbol, StateMachine] machines) {
	StateMachine machineToPlace = machines[tr.token];
	machineToPlace = prefixStates("<type(machine_sym, ())>" + "_" + tr.from + "_", machineToPlace);
	<from, tok, to> = tr;
	DeltaFunction newtrans = m.transitions;
	State newstart = m.startState;
	set[State] newfinal = m.finalStates;
	assert(size(newtrans - tr) == size(newtrans) - 1);
	newtrans -= tr;
	newtrans += <from, \eps(), machineToPlace.startState>;
	for(fs <- machineToPlace.finalStates) newtrans += <fs, \eps(), to>;
	newtrans += machineToPlace.transitions;
	return \sm-nfa(newtrans, newstart, newfinal);
}