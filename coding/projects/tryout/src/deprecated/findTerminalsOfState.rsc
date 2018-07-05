module syntax_highlighting::findTerminalsOfState

import Prelude;
import ParseTree;
import grammar2dfa::automata::StateMachine; 
import grammar2dfa::symbols::IsTerminal; 
import syntax_highlighting::aliases;

set[TokenPath] findTokenPathsOfState(map[Symbol, StateMachine] dfas, Symbol dfa_sym, State state) 
	= findTokenPathsOfStateHelper(dfas, dfa_sym, state, {dfa_sym}, []);

set[TokenPath] findTokenPathsOfStateHelper(map[Symbol, StateMachine] dfas, Symbol dfa_sym, State state, 
											   set[Symbol] passed, StateStack stack) {
	StateMachine dfa = dfas[dfa_sym];
	set[TokenPath] terminals = {};
	stack += <dfa_sym, state>;
	for (<tok, nextState> <- dfa.transitions[state]) {
		
		if(!isNonTerminalType(tok)) terminals += <stack, tok>;
		else if(\layouts(_) := tok) println(tok);
		else if(!(tok in passed)) terminals += findTokenPathsOfStateHelper(dfas, tok, dfas[tok].startState, passed+tok, stack);
	}
	if(state in dfa.finalStates) {
		terminals += <stack, \eps()>;
		//println(stack);
		//if(size(stack) > 1) {
		//	next_stack = stack[..-1];
		//	StateLabel parsed_machine = last(stack);
		//	StateLabel new_machine = last(next_stack);
		//	next_state = takeOneFrom(dfas[new_machine.machine].transitions[new_machine.state, parsed_machine.machine])[0];
		//	next_stack = next_stack[..-1];
		//	terminals += findTokenPathsOfStateHelper(dfas, new_machine.machine, next_state, passed, next_stack); 
		//}
	}
	return terminals;
}


set[set[TokenPath]] findConflicts(set[TokenPath] pathsOfState) {
	rel[Token, TokenPath] tokPathByTok = {<path.token, path> | path <- pathsOfState};
	return {tokPathByTok[tok] | tok <- {t[0] | t <- tokPathByTok}, size(tokPathByTok[tok]) > 1};
}

bool hasConflicts(set[TokenPath] pathsPerTransition)
	= !isEmpty(findConflicts(pathsPerTransition));