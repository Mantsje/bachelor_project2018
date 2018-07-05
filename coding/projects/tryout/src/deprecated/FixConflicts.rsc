module syntax_highlighting::FixConflicts

import Prelude;

import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;
import syntax_highlighting::findTerminalsOfState;
import syntax_highlighting::aliases;
import syntax_highlighting::matchesForContexts;

import grammar2dfa::symbols::ToRegex;
import grammar2dfa::automata::StateMachine;
import grammar2dfa::symbols::SymbolToString;

//TODO: probable propagate the scopes forward to the subcontexts when introducing them
//TODO: What happens when different paths with different lexicals lead to the same terminal in the end?
//  	-> probably (temporarily) wrong colouring? until we are sure which route we should take

/* For this path:
 * Get the last element of the path. Being the Machine that actually has the transition with tok
 * we have DFA's so te only reachable next_state with an \eps is the state self
 * Only add the new state if it has outgoing transitions
 * 
 * while:
 * The next_state is final, we possibly also advance in the machine above the current DFA
 * So set the token to the dfa_sym of the lower-level machine
 * advance the new DFA and do the same thing as with the old machine.
 */
 
set[StateLabel] getNextStateLabels(TokenPath path, map[Symbol, StateMachine] dfas) {
	set[StateLabel] labels = {};
	Token tok = path.token;
	StateLabel deepest_lab = last(path.stack);
	StateMachine deepest_dfa = dfas[deepest_lab.machine];
	State deepest_next_state = takeOneFrom(deepest_dfa.transitions[deepest_lab.state, tok])[0];
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

set[TokenPath] findNextTerminalsOfConflict(set[TokenPath] conflict, map[Symbol, StateMachine] dfas) {
	set[TokenPath] newPaths = {};
	for(path <- conflict) {
		newPaths += findNextTerminalsOfPath(path, dfas);
	}
	return newPaths;
}

/* Generates matches for the subcontext introduced by the functions below.
 * This adds matches for when we realize we are able to make a choice and push all remaining machines 
 * and continue as if we knew what we were doing all along
 */
set[Match] addMatchesConflictContext(set[TokenPath] paths, ContextMap contexts, map[Symbol, StateMachine] dfas, list[Symbol] terminal_lookahead, Token originalTok) {
	set[Match] matches = {};
	set[set[TokenPath]] conflicts = findConflicts(paths);
	non_conflicting_paths = paths - ({} | it + cset | cset <- conflicts);
	for(path <- non_conflicting_paths) {
		list[Context] contextList;
		//If the path was a terminal to begin with parse the terminal and go to the next state of the current_dfa_state
		//Is next lab because the original cur_lab is gone from these new paths
		StateLabel next_lab = head(path.stack);
		if(size(path.stack) == 1) {
			if(path.token == \eps()) contextList = [contexts[next_lab]];
			else {
				State next_state = takeOneFrom(dfas[next_lab.machine].transitions[next_lab.state, path.token])[0];
				Context next_context = contexts[<next_lab.machine, next_state>];
				contextList = [contexts[next_lab], contexts[<originalTok, dfas[originalTok].startState>]];
			}
		} else {
			StateLabel new_machine_lab = head(tail(path.stack));
			StateLabel new_machine_start_lab = <new_machine_lab.machine, dfas[new_machine_lab.machine].startState>;
			State next_state = takeOneFrom(dfas[next_lab.machine].transitions[next_lab.state, new_machine_lab.machine])[0];
			Context next_context = contexts[<next_lab.machine, next_state>];
			contextList = [next_context, contexts[new_machine_start_lab]];
		}		
		SHRegex regex = lookaheadRegexList(terminal_lookahead + path.token);
		matches += {\match-no-scope(regex, \setact([c.name | c <- contextList]))};
	}
	return matches;
}

//Create empty context with name indicating where the conflict is and about which token
Context createEmptyConflictContext(StateLabel statlab, Token tok)
	= \context-no-scope("<toAlnumString(statlab.state)>_CONF_<symbolToAlnumString(tok)>", {}, {});

/* Per conflict introduce one new Context function as inbetween state.
 * From here parse the expected token according to one of the possible derivation rules
 * We do not yet know what kind of part the user is writing, so can not possibly know for sure which context to use,
 * only what token is coming. So we randomly pick one of the options as highlighting mechanism.
 * IDEA: we could keep everything lookahead, this makes sure we do not have to choose. However also introduces the problem
 * of not colouring until we are able to decide. In some cases this could take a while. 
 * Next up find the new tokenpaths after we have supposedly parsed the current token
 * Now check whether conflicts remain, if so, recurse this process, else for all cases that have no conflicts add the choice
 * to our newly introduced context
 */
ContextMap fixConflict(set[TokenPath] conflict, ContextMap contexts, map[Symbol, StateMachine] dfas, StateLabel cur_lab) {
	Token conflictingToken = takeOneFrom(conflict)[0].token;
	subContext = createEmptyConflictContext(cur_lab, conflictingToken);
	//Add transitions to this new context
	SHRegex regex = lookaheadRegex(conflictingToken);
	pathChoice = takeOneFrom(conflict)[0];
	contexts[cur_lab].matches += {\match-no-scope(regex, \setact([subContext.name]))};
	
	println("conflict: <conflict>"); 	
	newPaths = findNextTerminalsOfConflict(conflict, dfas);
	println("new paths: <newPaths>"); 
	
	subContext.matches += addMatchesConflictContext(newPaths, contexts, dfas, [conflictingToken], conflictingToken);
	
	StateLabel subLabel = <\lit(subContext.name),"SUB">;
	contexts[subLabel] = subContext;
	fixedConflicts[conflict] = subLabel;
	set[set[TokenPath]] conflicts = findConflicts(newPaths);
	contexts = fixConflicts(conflicts, contexts, dfas, subLabel);
	return contexts;
}


map[set[TokenPath], StateLabel] fixedConflicts = ();
void clearFixedConflicts() { 
	fixedConflicts = ();
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

ContextMap fixTransitionalConflict(set[TokenPath] conflict, ContextMap contexts, map[Symbol, StateMachine] dfas, StateLabel cur_lab)
	 = addMatchesConflictlessContext(contexts, cur_lab, conflict, dfas);


//Fix all conflicts and change te ContextMap in doing so
ContextMap fixConflicts(set[set[TokenPath]] conflicts, ContextMap contexts, map[Symbol, StateMachine] dfas, StateLabel statlab) {	
	for(conflict <- conflicts) {
		if(isConflictInOneTransition(conflict)) {
			contexts = fixTransitionalConflict(conflict, contexts, dfas, statlab);
		} else {
			contexts = fixConflict(conflict, contexts, dfas, statlab);
		}
	}
	
	//for(conflict <- conflicts) {
		//println(conflict);
		//if(conflict in fixedConflicts) {
		//	subContext = contexts[fixedConflicts[conflict]];
		//	Token conflictingToken = takeOneFrom(conflict)[0].token;
		//	SHRegex regex = lookaheadRegex(conflictingToken);
		//	pathChoice = takeOneFrom(conflict)[0];
		//	tempContextChoice = contexts[last(pathChoice.stack)];
		//	contexts[fixedConflicts[conflict]].matches += {\match-no-scope(regex, \setact([subContext.name, tempContextChoice.name]))};
		//} else {
			//contexts = fixConflict(conflict, contexts, dfas, statlab);
		//}
	//}
	return contexts;
}