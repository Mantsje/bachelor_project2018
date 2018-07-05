module syntax_highlighting::ToContexts

import Prelude;

import grammar2dfa::automata::StateMachine;
import symbols::SymbolToString;

import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;
import syntax_highlighting::regexes::Main;

alias StateLabel = tuple[Symbol machine, State state];
alias ContextMap = map[StateLabel, Context];

map[Symbol, str] regexMap = ();

ContextMap generateEmptyContextMap(map[Symbol, StateMachine] dfas) {
	ContextMap contextmap = ();
	for (dfa_name <- dfas) {	
		StateMachine cur_dfa = dfas[dfa_name];
		set[State] states = getStates(cur_dfa);
		for (s <- states) contextmap += (<dfa_name, s>:\context("<symbolToAlnumString(dfa_name)>_<toAlnumString(s)>", \null(), {}, {}));
	}
	return contextmap;
}

/* checks wheter a state is final and has no outgoing transitions*/
bool isStateFinalSink(StateMachine fa, State s)
	= s in fa.finalStates && size(fa.transitions[s]) == 0;
 

set[Token] firstOfState(StateMachine m, State s, map[Symbol, StateMachine] machines) {
	set[Token] toks = {};
	for(<tok,_> <- m.transitions[s]) {
		if (tok in machines) { 
			toks += firstOfState(machines[tok], machines[tok].startState, machines);
		} else if (\conditional(Symbol inner_sym, set[Condition] conditions) := tok && inner_sym in machines) {	
			set[Condition] precons = {};
			for(con <- conditions) {
				<pref, post> = conditionRegex(con, regexMap);
				if (pref.regex != "()") precons += con;
			}
			if(isEmpty(precons)) toks += firstOfState(machines[inner_sym], machines[inner_sym].startState, machines);
			else toks += \conditional(\lit(""), precons);
		} else toks += tok;
	}
	return toks;
}

set[Token] firstOfStateExcept(set[Transition] except, StateMachine m, State s, map[Symbol, StateMachine] machines) {
	set[Token] toks = {};
	for(<tok,next> <- m.transitions[s]) {
		if(<s,tok,next> notin except) {
			if (tok in machines) {
				toks += firstOfState(machines[tok], machines[tok].startState, machines);
			} else if (\conditional(Symbol inner_sym, set[Condition] conditions) := tok && inner_sym in machines) {
			set[Condition] precons = {};
			for(con <- conditions) {
				<pref, post> = conditionRegex(con, regexMap);
				if (pref.regex != "()") precons += con;
			}
			if(isEmpty(precons)) toks += firstOfState(machines[inner_sym], machines[inner_sym].startState, machines);
			else toks += \conditional(\lit(""), precons);
			} else toks += tok;
		}
	}
	return toks;
}

set[Match] matchesForNonTerminal(StateLabel cur_lab, map[Symbol, StateMachine] dfas, Transition tr, ContextMap contexts) {
	set[Match] result = {};
	dfa = dfas[cur_lab.machine];
	set[Transition] toIgnore = { <tr.from,tok,next> | <tok, next> <- dfa.transitions[tr.from]} - tr;
	set[Symbol] termns = firstOfStateExcept(toIgnore, dfa, tr.from, dfas);
	Context next_context = contexts[<cur_lab.machine, tr.to>];
	StateLabel new_lab = <tr.token, dfas[tr.token].startState>;
	Context new_context = contexts[new_lab];
	if(isStateFinalSink(dfa, tr.to))
		return {\match(lookaheadRegexAlts(termns, regexMap), \null(), \setact([new_context.name]))};		
	else {
		return {\match(lookaheadRegexAlts(termns, regexMap), \null(), \setact([next_context.name, new_context.name]))};				
	}
}

tuple[ContextMap, int, StateLabel] contextsForConditions(
								ContextMap contexts, map[Condition, SHRegex] conditions,
								int cond_index, int cur_conditional_index, str infix,
								StateLabel temp_lab, str machineName) {
	for(p <- conditions) {
		StateLabel con_lab = <\lit("<machineName>_<infix>_<cond_index>_<cur_conditional_index>"), conditions[p].regex>;
		Context con_context = \context("<machineName>_<infix>_<cond_index>_<cur_conditional_index>", \null(), {}, {}, includePrototype=false);
		contexts[con_lab] = con_context;
		contexts[temp_lab].matches += {\match(conditions[p], \null(), \setact([con_context.name]))};
		temp_lab = con_lab;
		cur_conditional_index += 1;
	}
	return <contexts, cur_conditional_index, temp_lab>;
}

ContextMap conditionalContexts(StateLabel cur_lab, int cond_index, map[Symbol, StateMachine] dfas,
							   State next_state, ContextMap contexts, Symbol::\conditional(Symbol lh, set[Condition] conditions),
							   Scope match_scope) {
	StateMachine dfa = dfas[cur_lab.machine];
	machineName = symbolToAlnumString(cur_lab.machine);
	int cur_conditional_index = 0;
	prefixes = ();
	postfixes = ();

	//generate regexes for the conditions
	for(con <- conditions) {
		<pref, post> = conditionRegex(con, regexMap);
		if(pref.regex == "()") postfixes[con] = post;
		else prefixes[con] = pref;
	}	

	//For all prefixes, make a new context. 
	//From current context, match the precondition and go to this new_context
	StateLabel con_lab; Context con_context;		
	StateLabel temp_lab = cur_lab;	
	
	<contexts, cur_conditional_index, temp_lab> = contextsForConditions(contexts, prefixes, cond_index, 
													cur_conditional_index, "PRECOND", temp_lab, machineName);
	//Do the original contexting for the inner Symbol lh										
	new_lab = <\lit("<machineName>_INNER_<cond_index>_<cur_conditional_index>"), symbolToAlnumString(lh)>;
	new_context = \context("<machineName>_INNER_<cond_index>_<cur_conditional_index>", \null(), {}, {}, includePrototype=false);
	contexts[new_lab] = new_context;
	if (lh in dfas) {
		set[Symbol] termns = firstOfState(dfas[lh], dfas[lh].startState, dfas);
		contexts[temp_lab].matches +=  {\match(lookaheadRegexAlts(termns, regexMap), \null(), \setact([new_context.name, contexts[<lh, dfas[lh].startState>].name]))};	
	} else
		contexts[temp_lab].matches += {\match(toRegex(lh, regexMap), match_scope, \setact([new_context.name]))};
	temp_lab = new_lab;
	cur_conditional_index += 1;
	
	//For all postfixes, make a new context. 
	//From current context, match the postcondition and go to this new_context	
	<contexts, cur_conditional_index, temp_lab> = contextsForConditions(contexts, postfixes, cond_index, 
													cur_conditional_index, "POSTCOND", temp_lab, machineName);
	
	next_context = contexts[<cur_lab.machine, next_state>];	
	if(isStateFinalSink(dfa, next_state))
		contexts[temp_lab].matches += {\match(\str-regex(""), \null(), \pop())};		
	else
		contexts[temp_lab].matches += {\match(\str-regex(""), \null(), \setact([next_context.name]))};
	return contexts;
}

/* We assume that there are no conflicts left
 */
 tuple[Context, map[str, Context]] toContexts(map[Symbol, StateMachine] dfas, Symbol startSymbol
 											, map[Symbol, Scope] scopeMap, map[Symbol, str] regmap) {
 	regexMap = regmap;
 	ContextMap contexts = generateEmptyContextMap(dfas);
	for (dfa_sym <- dfas) {
		dfa = dfas[dfa_sym];
		machine_scope = \null();
		match_scope = \null();
		if(dfa_sym in scopeMap) {
			machine_scope  = scopeMap[dfa_sym];
		} else machine_scope = \null();
		int cond_index = 0;
		for(state <- getStates(dfa)) {
			StateLabel cur_lab = <dfa_sym, state>;
			for(<tok, next_state> <- dfa.transitions[state]) {	
				next_context = contexts[<dfa_sym, next_state>];		
				if (tok in dfas) {
					contexts[cur_lab].matches += matchesForNonTerminal(cur_lab, dfas, <state,tok,next_state>, contexts);
				//If we have a conditional
				} else if(\conditional(Symbol inner, _) := tok) {
					if(tok in scopeMap) {
						match_scope = scopeMap[tok];
						if(!(machine_scope is \null) && machine_scope != match_scope) println("Warning: token <tok> has a different scope than the dfa containing the token. Taking specific scope: <match_scope>");
					} else match_scope = machine_scope;
					contexts = conditionalContexts(cur_lab, cond_index, dfas, next_state, contexts, tok, match_scope);
					cond_index += 1;
				} else {
					if(tok in scopeMap) {
						match_scope = scopeMap[tok];
						if(!(machine_scope is \null) && machine_scope != match_scope) println("Warning: token <tok> has a different scope than the dfa containing the token. Taking specific scope: <match_scope>");
					} else match_scope = machine_scope;
					if(isStateFinalSink(dfa, next_state))
						contexts[cur_lab].matches += {\match(toRegex(tok, regexMap), match_scope, \pop())};					
					else 
						contexts[cur_lab].matches += {\match(toRegex(tok, regexMap), match_scope, \setact([next_context.name]))};	
				}
			}
			if(state in dfa.finalStates) 
				contexts[cur_lab].matches += {\match(negLookaheadRegexAlts({m.regex | m <- contexts[cur_lab].matches}), \null(), \pop())};	
		}
	}
	result = (contexts[tup].name:contexts[tup] | tup <- contexts);
	return <contexts[<startSymbol, dfas[startSymbol].startState>], result>;
 }
