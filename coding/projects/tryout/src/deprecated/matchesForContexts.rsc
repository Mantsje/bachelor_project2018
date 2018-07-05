module syntax_highlighting::matchesForContexts

import Prelude;

import grammar2dfa::automata::StateMachine;
import grammar2dfa::symbols::ToRegex;
import syntax_highlighting::aliases;
import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;

 /* checks wheter a state is final and has no outgoing transitions*/
 bool isStateFinalSink(StateMachine fa, State s)
 	= s in fa.finalStates && size(fa.transitions[s]) == 0;
 
SHRegex lookaheadRegex(Symbol s) {
	str str_regex = symbolToRegex(s);
	SHRegex regex = \str-regex("(?=(<str_regex>))");
	return regex;
}

SHRegex lookaheadRegexList(list[Symbol] syms) {
	list[str] str_regexes = [symbolToRegex(s) | s <- syms];
	str str_regex = ("" | it + str_regex + " " | str_regex <- str_regexes);
	SHRegex regex = \str-regex("(?=(<str_regex[..size(str_regex)-1]>))");
	return regex;
}
 
 
ContextMap matchesForSimpleTransition(ContextMap contexts, StateMachine dfa, Symbol dfa_sym, Transition tr) { 
	set[Match] matches = {};
	<cur_state, sym_tok, next_state> = tr;
	StateLabel cur_context_lab = <dfa_sym, cur_state>;
	StateLabel next_context_lab = <dfa_sym, next_state>;
	str str_regex = symbolToRegex(sym_tok);
	SHRegex regex = \str-regex(str_regex);
	//If next state is final and sink-like we don't need to finish this state, we are done and we can pop
	if (isStateFinalSink(dfa, next_state)) {
		contexts[cur_context_lab].matches += {\match-no-scope(regex, \pop())};
	//Means it still has outgoing transitions. For now, pop if nothing is matched, else go to the next state
	} else {
		contexts[cur_context_lab].matches += {\match-no-scope(regex, \setact([contexts[next_context_lab].name]))};
	}
	return contexts;
}

ContextMap handleEpsilon(ContextMap contexts, StateLabel cur_lab, TokenPath path,  map[Symbol, StateMachine] dfas) {
	if(size(path.stack) == 1) {
		contexts[cur_lab].matches += {\match-no-scope(\str-regex(""), \pop())};
	} else {
		State next_state = takeOneFrom(dfas[cur_lab.machine].transitions[cur_lab.state, head(tail(path.stack)).machine])[0];
		Context next_context = contexts[<cur_lab.machine, next_state>];
		Context new_context = contexts[head(tail(path.stack))];
		contexts[cur_lab].matches += {\match-no-scope(lookaheadRegex(\eps()), \setact([next_context.name, new_context.name]))};
	}
	return contexts;
}

ContextMap handleNewMachine(ContextMap contexts, StateLabel cur_lab, StateLabel next_lab, TokenPath path, map[Symbol, StateMachine] dfas) {
	cur_dfa = dfas[cur_lab.machine];
	next_state = next_lab.state;
	//Get second element of stack, since first is current machine
	new_dfa_name = head(tail(path.stack)).machine;
	new_dfa = dfas[new_dfa_name];
	new_lab = <new_dfa_name, new_dfa.startState>;
	new_context= contexts[<new_dfa_name, new_dfa.startState>];
	
	SHRegex regex = lookaheadRegex(path.token);	
	if (isStateFinalSink(cur_dfa, next_state)) {
		contexts[cur_lab].matches += {\match-no-scope(regex, \setact([new_context.name]))};
	} else {
		contexts[cur_lab].matches += {\match-no-scope(regex, \setact([contexts[next_lab].name, new_context.name]))};
	}
	return contexts;
}

/*Look into how we get this exact path and statlab.
*Probably create a function that just takes in 1 path and creates the sequence of matches for this
* sooo: lookahead(path.token), context.set[entire list of path]
* few things:
* cur_varname => has to do with current machine and current state
* next_varname => has to do with the next state of the current machine, the current DFA, the toplevel DFA. all one and the same
* new_varname => has to do with the next DFA to be pushed on top of the current DFA.
* flow is regularly: cur... -> new... -> next...
*/
ContextMap generateMatchesForPath(TokenPath path, StateLabel cur_lab, map[Symbol, StateMachine] dfas, ContextMap contexts) {
	//Should mean this is a final state
 	if (\eps() := path.token) return handleEpsilon(contexts, cur_lab, path, dfas);
	
	StateMachine cur_dfa = dfas[cur_lab.machine];
	State cur_state = cur_lab.state;
	
	Token cur_token;
	if(size(path.stack) > 1) cur_token = head(tail(path.stack)).machine;
	else cur_token = path.token;

	State next_state = takeOneFrom(cur_dfa.transitions[cur_state, cur_token])[0];
	StateLabel next_lab = <cur_lab.machine, next_state>;
	Transition cur_tr = <cur_state, path.token, next_state>;
	
	//Is this path a single terminal? I.E. no recursion	
	if (size(path.stack) == 1) {
		contexts = matchesForSimpleTransition(contexts, cur_dfa, cur_lab.machine, cur_tr);
	} else {
		contexts = handleNewMachine(contexts, cur_lab, next_lab, path, dfas);
	}
	return contexts;
}


ContextMap addMatchesConflictlessContext(ContextMap contexts, StateLabel statlab, 
									  set[TokenPath] tokenpaths, map[Symbol, StateMachine] dfas) {
	for (path <- tokenpaths) contexts = generateMatchesForPath(path, statlab, dfas, contexts);
	
	return contexts;
}