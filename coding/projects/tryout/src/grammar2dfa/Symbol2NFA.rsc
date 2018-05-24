module grammar2dfa::Symbol2NFA

import Grammar;
import IO;

import grammar2dfa::symbols::IsTerminal;
import grammar2dfa::automata::StateMachine;

StateMachine generateNFA_Terminal(State startState, State finalState, Symbol s) {
	DeltaFunction trans = {};
	trans += <startState, s, finalState>;
	return \sm-nfa(trans, startState, {finalState});	
}

StateMachine generateNFA_lit(State startState, State finalState, Symbol s)
	= generateNFA_Terminal(startState, finalState, s);

StateMachine generateNFA_cilit(State startState, State finalState, Symbol s)
	= generateNFA_Terminal(startState, finalState, s);

StateMachine generateNFA_charclass(State startState, State finalState, Symbol s)
	= generateNFA_Terminal(startState, finalState, s);

StateMachine generateNFA_opt(State startState, State finalState, Symbol optional_sym) {
	DeltaFunction trans = {};
	trans += <startState, optional_sym, finalState>;
	trans += <startState, \eps(), finalState>;
	return \sm-nfa(trans, startState, {finalState});
}

StateMachine generateNFA_iter(State startState, State finalState, Symbol iter_sym) {
	DeltaFunction trans = {};
	trans += <startState, iter_sym, finalState>;
	trans += <finalState, iter_sym, finalState>;
	return \sm-nfa(trans, startState, {finalState});
}

StateMachine generateNFA_iterstar(State startState, State finalState, Symbol iter_sym) {
	StateMachine out = generateNFA_iter(startState, finalState, iter_sym);
	return \sm-nfa(out.transitions + <startState, \eps(), finalState>, out.startState, out.finalStates);
}

//TODO: get checked wheter list here means all of of these in order, or just one of them? if so, why no set then?
StateMachine generateNFA_iterseps(State startState, State finalState, Symbol iter_sym, list[Symbol] seps) {	
	DeltaFunction trans = {};
	subIndex = 0;
	nextState = "in<0>_<subIndex>_<tokenToString(iter_sym)>";
	firstState = nextState;
	trans += <startState, iter_sym, nextState>;
	trans += <nextState, \eps(), finalState>;
	for(sep <- seps) {
		if(\layouts(_) := sep) continue;
		subIndex += 1;
		curState = nextState;
		nextState = "in<0>_<subIndex>_<tokenToString(iter_sym)>";
		trans += <curState, sep, nextState>;	
	}
	trans += <nextState, iter_sym, firstState>;
	return \sm-nfa(trans, startState, {finalState});
	
}
  
StateMachine generateNFA_iterstarseps(State startState, State finalState, Symbol iter_sym, list[Symbol] seps) {
	StateMachine out = generateNFA_iterseps(startState, finalState, iter_sym, seps);
	DeltaFunction trans = out.transitions;
	trans += <startState, \eps(), finalState>;
	return \sm-nfa(trans, out.startState, out.finalStates);
}

StateMachine generateNFA_alt(State startState, State finalState, set[Symbol] alts) {
	DeltaFunction trans = {};
	for (alter <- alts) trans += <startState, alter, finalState>;
	return \sm-nfa(trans, startState, {finalState});
}

StateMachine generateNFA_seq(State startState, State finalState, list[Symbol] syms, Symbol par) {
	DeltaFunction trans = {};
	subIndex = 0;
	nextState = "in<0>_<subIndex>_<tokenToString(par)>";
	curState = startState;
	for(s <- syms) {
		if(\layouts(_) := s) continue;
		trans += <curState, s, nextState>;	
		subIndex += 1;
		curState = nextState;
		nextState = "in<0>_<subIndex>_<tokenToString(par)>";
	}
	trans += <curState, \eps(), finalState>;
	return \sm-nfa(trans, startState, {finalState});
}

StateMachine generateNFA_conditional(State startState, State finalState, Symbol s) {
	if (!isTerminal(s)) println("Conditional Symbol is not a terminal <s>");
	DeltaFunction trans = {};
	trans += <startState, s, finalState>;
	return \sm-nfa(trans, startState, {finalState});
}

StateMachine NFAForSymbol(State startState, State endState, Symbol target) {
	switch(target) {
		case \lit(_): 			return generateNFA_lit(startState, endState, target);
		case \cilit(_): 		return generateNFA_cilit(startState, endState, target);
		case \char-class(_): 	return generateNFA_charclass(startState, endState, target);
		
		case \opt(Symbol opt_sym): 			return generateNFA_opt(startState, endState, opt_sym);		
		case \iter(Symbol iter_sym): 		return generateNFA_iter(startState, endState, iter_sym);
		case \iter-star(Symbol iter_sym): 	return generateNFA_iterstar(startState, endState, iter_sym);
				
		case \iter-seps(Symbol s, list[Symbol] separators): 
			return generateNFA_iterseps(startState, endState, s, separators);
		case \iter-star-seps(Symbol s, list[Symbol] separators): 
			return generateNFA_iterstarseps(startState, endState, s, separators);
			
		case \alt(set[Symbol] alternatives): 	return generateNFA_alt(startState, endState, alternatives);
		case \seq(list[Symbol] syms): 			return generateNFA_seq(startState, endState, syms, target);
		
		case \conditional(Symbol s, set[Condition] conditions):
			return generateNFA_conditional(startState, endState, target);
		
		default: throw error("Non_exhaustive pattern match StateMachineNoRuleSymbol: <target>");
	}
}	
