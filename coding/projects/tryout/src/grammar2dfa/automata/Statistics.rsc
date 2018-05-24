module grammar2dfa::automata::Statistics

import Prelude;

import grammar2dfa::automata::StateMachine;

/* Some functions that give and print some information on state machines*/

map[tuple[State, Token], set[State]] deltaToMap(DeltaFunction d) {
	new_delta = (<t[0], t[1]>:{} | t <- d);
	for (t<- d) new_delta[<t[0], t[1]>] += t[2];
	return new_delta;
}

map[State, int] stateTransitionCount(StateMachine fa) {
	newD = deltaToMap(fa.transitions);
	map[State, int] trans_cnt = (t[0]:0 | t <- fa.transitions);
	for (tup <- newD) trans_cnt[tup[0]] += size(newD[tup]); 
	return trans_cnt;
}

tuple[int, tuple[int, int, int]] transitionTypes(StateMachine fa) {
	int gt_one = 0;
	int eq_one = 0;
	int num_states = 0;
	num_states += size(getStates(fa));
	trans_cnt = stateTransitionCount(dfa);
	for(s <- trans_cnt) {
		if (trans_cnt[s] == 1) 	eq_one += 1;
		else 					gt_one += 1;
	}
	int lt_one = num_states - gt_one - eq_one;
	return <num_states, <lt_one, eq_one, gt_one>>;
}

void printInfoStateMachines(map[str, StateMachine] fas) {
	ss = 0; lt_one = 0; eq_one = 0; gt_one = 0;
	for(name <- fas) {
		fa = fas[name];
		<a, <b, c, d>> = transitionTypes(fa);
		ss 		+= a;
		lt_one	+= b;
		eq_one	+= c;
		gt_one 	+= d;	
	}
	println("num_states: <ss>");
	println("num_states with out-degree of =1: <eq_one>");
	println("num_states with out-degree \>1: <gt_one>");	
	println("num_states with out-degree 0: <lt_one>");	
	singletransDFAs = {fas[d] | d <- fas, size(fas[d].transitions) == 1};
	for(df <- singletransDFAs) println(df);
	println("num dfas with single transition: <size(singletransDFAs)> / <size(fas)>");
}

void printInfoStateMachine(StateMachine fa) {
	<a, <b, c, d>> = transitionTypes(fa);
	ss 		= a;
	lt_one	= b;
	eq_one	= c;
	gt_one 	= d;		
	println("num_states: <ss>");
	println("num_states with out-degree of =1: <eq_one>");
	println("num_states with out-degree \>1: <gt_one>");	
	println("num_states with out-degree 0: <lt_one>");	
}

/* more than one, so either 0 or 1*/
set[State] multipleTransitionStates(StateMachine fa)
	= {s | s <- getStates(fa), size(fa.transitions[s]) > 0};
